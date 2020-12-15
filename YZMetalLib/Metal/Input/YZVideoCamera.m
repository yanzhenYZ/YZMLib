//
//  YZVideoCamera.m
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/9.
//

#import "YZVideoCamera.h"
#import <Metal/Metal.h>
#import "YZMetalDevice.h"
#import "YZVideoCamera.h"
#import "YZMetalOrientation.h"
#import "YZShaderTypes.h"
#import "YZYUVToRGBConversion.h"

@interface YZVideoCamera ()<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDevice *camera;
@property (nonatomic, strong) AVCaptureDeviceInput *input;
@property (nonatomic, strong) AVCaptureVideoDataOutput *output;
@property (nonatomic, copy) AVCaptureSessionPreset preset;

@property (nonatomic, strong) id<MTLRenderPipelineState> renderPipelineState;
@property (nonatomic, assign) CVMetalTextureCacheRef textureCache;
@property (nonatomic, assign) YZOrientation orientation;
@property (nonatomic, assign) BOOL userBGRA;
@property (nonatomic, assign) BOOL fullYUVRange;
@property (nonatomic, assign) int dropFrames;
@end

@implementation YZVideoCamera {
    dispatch_queue_t _cameraQueue;
    dispatch_queue_t _cameraRenderQueue;
    dispatch_semaphore_t _videoSemaphore;
    const float *_colorConversion; //4x3
}

- (instancetype)initWithSessionPreset:(AVCaptureSessionPreset)preset
{
    self = [super init];
    if (self) {
        _orientation = YZOrientationPortrait;
        _cameraQueue = dispatch_queue_create("com.yanzhen.video.camera.queue", 0);
        _cameraRenderQueue = dispatch_queue_create("com.yanzhen.video.camera.render.queue", 0);
        _videoSemaphore = dispatch_semaphore_create(1);
        //_userBGRA = YES;
        _preset = preset;
        [self _configVideoSession];
        [self _configMetal];
    }
    return self;
}

- (void)startRunning {
    dispatch_semaphore_wait(_videoSemaphore, DISPATCH_TIME_FOREVER);
    if (!_session.isRunning) {
        [_session startRunning];
    }
    dispatch_semaphore_signal(_videoSemaphore);
}

- (void)stopRunning
{
    dispatch_semaphore_wait(_videoSemaphore, DISPATCH_TIME_FOREVER);
    if (_session.isRunning) {
        [_session stopRunning];
    }
    dispatch_semaphore_signal(_videoSemaphore);
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate and metal frame
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (!_session.isRunning) { return; }
    if (_output != output) { return; }
    if (dispatch_semaphore_wait(_videoSemaphore, DISPATCH_TIME_NOW) != 0) {
        _dropFrames++;
        return;
    }
    CFRetain(sampleBuffer);
    dispatch_async(_cameraRenderQueue, ^{
        if ([self.delegate respondsToSelector:@selector(videoCamera:output:)]) {
            [self.delegate videoCamera:self output:sampleBuffer];
        }
        if (self.userBGRA) {
            [self _processBGRAVideoSampleBuffer:sampleBuffer];
        } else {
            [self _processYUVVideoSampleBuffer:sampleBuffer];
        }
        CFRelease(sampleBuffer);
        dispatch_semaphore_signal(self->_videoSemaphore);
    });
}

- (void)_processBGRAVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    CVMetalTextureRef textureRef = NULL;
    id<MTLTexture> texture = NULL;
    CVReturn status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCache, pixelBuffer, nil, MTLPixelFormatBGRA8Unorm, width, height, 0, &textureRef);
    if (status == kCVReturnSuccess) {
        texture = CVMetalTextureGetTexture(textureRef);
        CFRelease(textureRef);
        textureRef = NULL;
    }
    
    MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:height height:width mipmapped:NO];
    desc.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite | MTLTextureUsageRenderTarget;
    id<MTLTexture> outputTexture = [YZMetalDevice.defaultDevice.device newTextureWithDescriptor:desc];
    
    [self _converWH:texture outputTexture:outputTexture];
    
    [self.view newTextureAvailable:outputTexture index:0];
}

- (void)_converWH:(id<MTLTexture>)bgraTexture outputTexture:(id<MTLTexture>)texture {
    id<MTLCommandBuffer> commandBuffer = [YZMetalDevice.defaultDevice.commandQueue commandBuffer];
    const float *squareVertices = [YZMetalOrientation defaultVertices];
    id<MTLBuffer> vertexBuffer = [YZMetalDevice.defaultDevice.device newBufferWithBytes:squareVertices length:sizeof(float) * 8 options:MTLResourceCPUCacheModeDefaultCache];
    vertexBuffer.label = @"YZVideoCamera VertexBuffer";
    
    MTLRenderPassDescriptor *desc = [[MTLRenderPassDescriptor alloc] init];
    desc.colorAttachments[0].texture = texture;
    desc.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 1, 1);
    desc.colorAttachments[0].storeAction = MTLStoreActionStore;
    desc.colorAttachments[0].loadAction = MTLLoadActionClear;
    
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:desc];
    if (!encoder) {
        NSLog(@"YZVideoCamera render endcoder Fail");
    }
    [encoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [encoder setRenderPipelineState:self.renderPipelineState];
    [encoder setVertexBuffer:vertexBuffer offset:0 atIndex:YZRGBVertexIndexPosition];
    
    //bgra
    const float *bgraSquareVertices = [YZMetalOrientation getCoordinates:YZOrientationLeft];
    id<MTLBuffer> rgbBuffer = [YZMetalDevice.defaultDevice.device newBufferWithBytes:bgraSquareVertices length:sizeof(float) * 8 options:MTLResourceCPUCacheModeDefaultCache];
    rgbBuffer.label = @"YZVideoCamera RGBBuffer";
    [encoder setVertexBuffer:rgbBuffer offset:0 atIndex:YZRGBVertexIndexRGB];
    [encoder setFragmentTexture:bgraTexture atIndex:YZRGBFragmentIndexTexture];
    
    [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    [encoder endEncoding];
    
    [commandBuffer commit];
    
}

- (void)_processYUVVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVMetalTextureRef textureRef = NULL;
    id<MTLTexture> textureY = NULL;
    //y
    size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
    size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
    CVReturn status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCache, pixelBuffer, NULL, MTLPixelFormatR8Unorm, width, height, 0, &textureRef);
    if(status == kCVReturnSuccess) {
        textureY = CVMetalTextureGetTexture(textureRef);
        CFRelease(textureRef);
        textureRef = NULL;
    }
    //uv
    id<MTLTexture> textureUV = NULL;
    width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1);
    height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1);
    status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCache, pixelBuffer, NULL, MTLPixelFormatRG8Unorm, width, height, 1, &textureRef);
    if(status == kCVReturnSuccess) {
        textureUV = CVMetalTextureGetTexture(textureRef);
        CFRelease(textureRef);
        textureRef = NULL;
    }
    
    size_t outputW = CVPixelBufferGetHeight(pixelBuffer);
    size_t outputH = CVPixelBufferGetWidth(pixelBuffer);
    MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:outputW height:outputH mipmapped:NO];
    desc.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite | MTLTextureUsageRenderTarget;
    id<MTLTexture> outputTexture = [YZMetalDevice.defaultDevice.device newTextureWithDescriptor:desc];
    CFTypeRef attachment = CVBufferGetAttachment(pixelBuffer, kCVImageBufferYCbCrMatrixKey, NULL);
    if (attachment != NULL) {
        if(CFStringCompare(attachment, kCVImageBufferYCbCrMatrix_ITU_R_601_4, 0) == kCFCompareEqualTo) {
            if (_fullYUVRange) {
                _colorConversion = kYZColorConversion601FullRange;
            } else {
                _colorConversion = kYZColorConversion601;
            }
        } else {
            _colorConversion = kYZColorConversion709;
        }
    } else {
        if (_fullYUVRange) {
            _colorConversion = kYZColorConversion601FullRange;
        } else {
            _colorConversion = kYZColorConversion601;
        }
    }
    
    [self _convertYUVToRGB:textureY textureUV:textureUV outputTexture:outputTexture];
    
//    [self testPixelBuffer:outputTexture];
    
    [self.view newTextureAvailable:outputTexture index:0];
}

- (void)testPixelBuffer:(id<MTLTexture>)texture {
    
    NSUInteger width = texture.width;
    NSUInteger height = texture.height;
    
    NSDictionary *pixelAttributes = @{(NSString *)kCVPixelBufferIOSurfacePropertiesKey:@{}};
    
    CVPixelBufferRef pixelBuffer = NULL;
    CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault,
                                            width,
                                            height,
                                            kCVPixelFormatType_32BGRA,
                                            (__bridge CFDictionaryRef)(pixelAttributes),
                                            &pixelBuffer);
    if (result != kCVReturnSuccess) {
        NSLog(@"Unable to create cvpixelbuffer %d", result);
        return;
    }
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *address = CVPixelBufferGetBaseAddress(pixelBuffer);
    if (address) {
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
        
        MTLRegion region = MTLRegionMake2D(0, 0, width, height);
        [texture getBytes:address bytesPerRow:bytesPerRow fromRegion:region mipmapLevel:0];
//        NSLog(@"%@", pixelBuffer);
    }
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    if ([_delegate respondsToSelector:@selector(outputBuffer:)]) {
        [_delegate outputBuffer:pixelBuffer];
    }
    
    CVPixelBufferRelease(pixelBuffer);
}

- (void)_convertYUVToRGB:(id<MTLTexture>)textureY textureUV:(id<MTLTexture>)textureUV outputTexture:(id<MTLTexture>)texture {
    id<MTLCommandBuffer> commandBuffer = [YZMetalDevice.defaultDevice.commandQueue commandBuffer];
    const float *squareVertices = [YZMetalOrientation defaultVertices];
    id<MTLBuffer> vertexBuffer = [YZMetalDevice.defaultDevice.device newBufferWithBytes:squareVertices length:sizeof(float) * 8 options:MTLResourceCPUCacheModeDefaultCache];
    vertexBuffer.label = @"YZVideoCamera VertexBuffer";
    
    MTLRenderPassDescriptor *desc = [[MTLRenderPassDescriptor alloc] init];
    desc.colorAttachments[0].texture = texture;
    desc.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 1, 1);
    desc.colorAttachments[0].storeAction = MTLStoreActionStore;
    desc.colorAttachments[0].loadAction = MTLLoadActionClear;
    
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:desc];
    if (!encoder) {
        NSLog(@"YZVideoCamera render endcoder Fail");
    }
    [encoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [encoder setRenderPipelineState:self.renderPipelineState];
    [encoder setVertexBuffer:vertexBuffer offset:0 atIndex:YZFullRangeVertexIndexPosition];
    
    //yuv
    const float *yuvSquareVertices = [YZMetalOrientation getCoordinates:YZOrientationLeft];
    id<MTLBuffer> yBuffer = [YZMetalDevice.defaultDevice.device newBufferWithBytes:yuvSquareVertices length:sizeof(float) * 8 options:MTLResourceCPUCacheModeDefaultCache];
    yBuffer.label = @"YZVideoCamera YBuffer";
    [encoder setVertexBuffer:yBuffer offset:0 atIndex:YZFullRangeVertexIndexY];
    [encoder setFragmentTexture:textureY atIndex:YZFullRangeFragmentIndexTextureY];
    
    id<MTLBuffer> uvBuffer = [YZMetalDevice.defaultDevice.device newBufferWithBytes:yuvSquareVertices length:sizeof(simd_float8) options:MTLResourceCPUCacheModeDefaultCache];
    uvBuffer.label = @"YZVideoCamera UVBuffer";
    [encoder setVertexBuffer:uvBuffer offset:0 atIndex:YZFullRangeVertexIndexUV];
    [encoder setFragmentTexture:textureUV atIndex:YZFullRangeFragmentIndexTextureUV];

    //coversion
    id<MTLBuffer> uniformBuffer = [YZMetalDevice.defaultDevice.device newBufferWithBytes:_colorConversion length:sizeof(float) * 12 options:MTLResourceCPUCacheModeDefaultCache];
    [encoder setFragmentBuffer:uniformBuffer offset:0 atIndex:YZFullRangeUniform];
    
    [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    [encoder endEncoding];
    
    [commandBuffer commit];
}

#pragma mark - private
- (void)_configMetal {
    CVMetalTextureCacheCreate(kCFAllocatorDefault, NULL, YZMetalDevice.defaultDevice.device, NULL, &_textureCache);
}

- (void)_configVideoSession {
    _session = [[AVCaptureSession alloc] init];
    _camera = [YZVideoCamera defaultFrontDevice];
    NSError *error = nil;
    _input = [[AVCaptureDeviceInput alloc] initWithDevice:_camera error:&error];
    if (error) {
        NSLog(@"YZVideoCamera error:%@", error);
        return;
    }
    [_session beginConfiguration];
    
    if ([_session canAddInput:_input]) {
        [_session addInput:_input];
    }
    
    _output = [[AVCaptureVideoDataOutput alloc] init];
    _output.alwaysDiscardsLateVideoFrames = NO;
    [_output setSampleBufferDelegate:self queue:_cameraQueue];
        
    if (_userBGRA) {
        _renderPipelineState = [YZMetalDevice.defaultDevice newRenderPipeline:@"YZYRGBVertex" fragment:@"YZRGBRotationFragment"];
        NSDictionary *dict = @{
            (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)
        };
        _output.videoSettings = dict;
    } else {
        NSArray<NSNumber *> *availableVideoCVPixelFormatTypes = _output.availableVideoCVPixelFormatTypes;
        [availableVideoCVPixelFormatTypes enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.longLongValue == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
                self.fullYUVRange = YES;
            }
        }];
        
        if (_fullYUVRange) {
            _renderPipelineState = [YZMetalDevice.defaultDevice newRenderPipeline:@"YZYUVToRGBVertex" fragment:@"YZYUVConversionFullRangeFragment"];
            NSDictionary *dict = @{
                (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
            };
            _output.videoSettings = dict;
        } else {
            _renderPipelineState = [YZMetalDevice.defaultDevice newRenderPipeline:@"YZYUVToRGBVertex" fragment:@"YZYUVConversionVideoRangeFragment"];
            NSDictionary *dict = @{
                (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
            };
            _output.videoSettings = dict;
        }
    }
    
    if ([_session canAddOutput:_output]) {
        [_session addOutput:_output];
    }
    
    if ([_session canSetSessionPreset:_preset]) {
        _session.sessionPreset = _preset;
    }
    
    [_session commitConfiguration];
}

+ (AVCaptureDevice *)defaultFrontDevice {
    if (@available(iOS 10.0, *)) {
        return [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
    } else {
        NSArray<AVCaptureDevice *> *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        __block AVCaptureDevice *device = nil;
        [devices enumerateObjectsUsingBlock:^(AVCaptureDevice * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.position == AVCaptureDevicePositionFront) {
                device = obj;
                *stop = YES;
            }
        }];
        return device;
    }
    return nil;
}
@end
