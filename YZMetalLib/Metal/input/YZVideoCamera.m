//
//  YZVideoCamera.m
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/9.
//

#import "YZVideoCamera.h"
#import <Metal/Metal.h>
#import "YZMetalRenderingDevice.h"
#import "YZYUVToRGBConversion.h"
#import "YZMetalOrientation.h"
#import "YZTexture.h"
#import "YZVideoCamera.h"

@interface YZVideoCamera ()<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDevice *camera;
@property (nonatomic, strong) AVCaptureDeviceInput *input;
@property (nonatomic, strong) AVCaptureVideoDataOutput *output;
@property (nonatomic, copy) AVCaptureSessionPreset preset;

@property (nonatomic, assign) CVMetalTextureCacheRef textureCache;
@property (nonatomic, assign) UIInterfaceOrientation orientation;
@property (nonatomic, assign) BOOL fullYUVRange;
@property (nonatomic, assign) int dropFrames;
@end

@implementation YZVideoCamera {
    dispatch_queue_t _cameraQueue;
    dispatch_queue_t _cameraRenderQueue;
    dispatch_semaphore_t _videoSemaphore;
}

- (instancetype)initWithSessionPreset:(AVCaptureSessionPreset)preset
{
    self = [super init];
    if (self) {
        _orientation = UIInterfaceOrientationPortrait;
        _cameraQueue = dispatch_queue_create("com.yanzhen.video.camera.queue", 0);
        _cameraRenderQueue = dispatch_queue_create("com.yanzhen.video.camera.render.queue", 0);
        _videoSemaphore = dispatch_semaphore_create(1);
        _preset = preset;
        [self _configVideoSession];
        [self _configMetal];
    }
    return self;
}

- (void)startRunning {
    if (!_session.isRunning) {
        [_session startRunning];
    }
}

- (void)stopRunning
{
    if (_session.isRunning) {
        [_session stopRunning];
    }
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
        [self _processVideoSampleBuffer:sampleBuffer];
        CFRelease(sampleBuffer);
        dispatch_semaphore_signal(self->_videoSemaphore);
    });
}

- (void)_processVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CMTime currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVMetalTextureRef texture = NULL;
    id<MTLTexture> textureY = NULL;
    id<MTLTexture> textureUV = NULL;
    //y
    MTLPixelFormat pixelFormat = MTLPixelFormatR8Unorm;
    size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
    size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
    CVReturn status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCache, pixelBuffer, NULL, pixelFormat, width, height, 0, &texture);
    if(status == kCVReturnSuccess) {
        textureY = CVMetalTextureGetTexture(texture);
        CFRelease(texture);
        texture = NULL;
    }
    //uv
    texture = NULL;
    pixelFormat = MTLPixelFormatRG8Unorm;
    width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1);
    height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1);
    
    status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCache, pixelBuffer, NULL, pixelFormat, width, height, 1, &texture);
    if(status == kCVReturnSuccess) {
        textureUV = CVMetalTextureGetTexture(texture);
        CFRelease(texture);
    }
    
    matrix_float3x3 conversionMatrix;
    if (_fullYUVRange) {
        conversionMatrix = kYZColorConversion601FullRangeMatrix;
    } else {
        conversionMatrix = kYZColorConversion601DefaultMatrix;
    }
    //根据方向获取旋转矩阵 - todo
    width = CVPixelBufferGetWidth(pixelBuffer);
    height = CVPixelBufferGetHeight(pixelBuffer);
    size_t outputW = width;
    size_t outputH = height;
    BOOL need = [YZMetalOrientation needRotation:_orientation width:width height:height];
    if (need) {
        outputW = height;
        outputH = width;
    }
    YZTexture *outputTexture = [[YZTexture alloc] initWithOrientation:_orientation width:outputW height:outputH];
    [self _convertYUVToRGB:textureY textureUV:textureUV outputTexture:outputTexture matrix:conversionMatrix];
    
    //todo
    [self.view newTextureAvailable:outputTexture index:0];
}

- (void)_convertYUVToRGB:(id<MTLTexture>)textureY textureUV:(id<MTLTexture>)textureUV outputTexture:(YZTexture *)texture matrix:(matrix_float3x3)matrix {
    YZTexture *newTextureY = [[YZTexture alloc] initWithOrientation:_orientation texture:textureY];
    YZTexture *newTextureUV = [[YZTexture alloc] initWithOrientation:_orientation texture:textureUV];
    YZShaderUniform *uniform = [YZMetalRenderingDevice.share getRenderUniform];
    uniform.colorConversionMatrix = matrix;
    //commandBuffer
    id<MTLCommandBuffer> commandBuffer = [YZMetalRenderingDevice.share.commandQueue commandBuffer];
    
    static const simd_float8 squareVertices[] = {
        -1.0f, 1.0f,
        1.0f, 1.0f,
        -1.0f,  -1.0f,
        1.0f,  -1.0f,
    };

    id<MTLBuffer> vertexBuffer = [YZMetalRenderingDevice.share.device newBufferWithBytes:squareVertices length:sizeof(squareVertices) options:MTLResourceCPUCacheModeDefaultCache];
    vertexBuffer.label = @"YZVertices";
    
    MTLRenderPassDescriptor *desc = [[MTLRenderPassDescriptor alloc] init];
    desc.colorAttachments[0].texture = texture.texture;
    desc.colorAttachments[0].clearColor = MTLClearColorMake(1, 0, 0, 1);
    desc.colorAttachments[0].storeAction = MTLStoreActionStore;
    desc.colorAttachments[0].loadAction = MTLLoadActionClear;
    
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:desc];
    if (!encoder) {
        NSLog(@"YZVideoCamera render endcoder Fail");
    }
    [encoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [encoder setRenderPipelineState:YZMetalRenderingDevice.share.renderPipelineState];
    [encoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];
    //texture
    static const simd_float8 uvSquareVertices[] = {
        1.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
    };
    id<MTLBuffer> yBuffer = [YZMetalRenderingDevice.share.device newBufferWithBytes:uvSquareVertices length:sizeof(uvSquareVertices) options:MTLResourceCPUCacheModeDefaultCache];
    yBuffer.label = @"YBuffer";
    [encoder setVertexBuffer:yBuffer offset:0 atIndex:1];
    [encoder setFragmentTexture:newTextureY.texture atIndex:0];
    
    id<MTLBuffer> uvBuffer = [YZMetalRenderingDevice.share.device newBufferWithBytes:uvSquareVertices length:sizeof(uvSquareVertices) options:MTLResourceCPUCacheModeDefaultCache];
    uvBuffer.label = @"UVBuffer";
    [encoder setVertexBuffer:uvBuffer offset:0 atIndex:2];
    [encoder setFragmentTexture:newTextureUV.texture atIndex:1];
    
    //todo
    matrix_float3x3 *ad = &matrix;
    id<MTLBuffer> uniformBuffer = [YZMetalRenderingDevice.share.device newBufferWithBytes:ad length:sizeof(matrix_float3x3) options:MTLResourceCPUCacheModeDefaultCache];
    [encoder setFragmentBuffer:uniformBuffer offset:0 atIndex:1];
    
    [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    [encoder endEncoding];
    [commandBuffer commit];
}

#pragma mark - private
- (void)_configMetal {
    CVMetalTextureCacheCreate(kCFAllocatorDefault, NULL, YZMetalRenderingDevice.share.device, NULL, &_textureCache);
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
    
    _output = [[AVCaptureVideoDataOutput alloc] init];
    _output.alwaysDiscardsLateVideoFrames = NO;
    [_output setSampleBufferDelegate:self queue:_cameraQueue];
    
    NSArray<NSNumber *> *availableVideoCVPixelFormatTypes = _output.availableVideoCVPixelFormatTypes;
    [availableVideoCVPixelFormatTypes enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.longLongValue == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
            self.fullYUVRange = YES;
        }
    }];
    
    //todo add bgra
    if (self.fullYUVRange) {
        [YZMetalRenderingDevice.share generateRenderPipelineState:YES];
        [_output setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    } else {
        [YZMetalRenderingDevice.share generateRenderPipelineState:NO];
        [_output setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    }
    
    [_session beginConfiguration];
    
    if ([_session canAddInput:_input]) {
        [_session addInput:_input];
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
        return [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
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
