//
//  YZCamera.m
//  YZMetalLib
//
//  Created by 闫振 on 2020/12/11.
//

#import "YZCamera.h"
#import <AVFoundation/AVFoundation.h>
#import <Metal/Metal.h>
#import "YZMetalRenderingDevice.h"

@interface YZCamera ()<AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDevice *camera;
@property (nonatomic, strong) AVCaptureDeviceInput *input;
@property (nonatomic, strong) AVCaptureVideoDataOutput *output;
@property (nonatomic, copy) AVCaptureSessionPreset preset;

@property (nonatomic, strong) id<MTLRenderPipelineState> renderPipelineState;
@property (nonatomic, assign) CVMetalTextureCacheRef textureCache;
@property (nonatomic, assign) BOOL fullYUVRange;
@property (nonatomic, assign) int dropFrames;
@end

@implementation YZCamera {
    dispatch_queue_t _cameraQueue;
    dispatch_queue_t _cameraRenderQueue;
    dispatch_semaphore_t _videoSemaphore;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _cameraQueue = dispatch_queue_create("com.yanzhen.video.camera.queue", 0);
        _cameraRenderQueue = dispatch_queue_create("com.yanzhen.video.camera.render.queue", 0);
        _videoSemaphore = dispatch_semaphore_create(1);
        
        _session = [[AVCaptureSession alloc] init];
        [_session beginConfiguration];
        
        AVCaptureDevice *device = [YZCamera defaultFrontDevice];
        _input = [[AVCaptureDeviceInput alloc] initWithDevice:device error:nil];
        if ([_session canAddInput:_input]) {
            [_session addInput:_input];
        }
        
        _output = [[AVCaptureVideoDataOutput alloc] init];
        _output.alwaysDiscardsLateVideoFrames = NO;
        
        id<MTLFunction> vertexFunction = [YZMetalRenderingDevice.share.defaultLibrary newFunctionWithName:@"twoInputVertex"];
        id<MTLFunction> fragmentFunction = [YZMetalRenderingDevice.share.defaultLibrary newFunctionWithName:@"yuvConversionFullRangeFragment"];
        
        MTLRenderPipelineDescriptor *desc = [[MTLRenderPipelineDescriptor alloc] init];
        desc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;//bgra
        desc.rasterSampleCount = 1;
        desc.vertexFunction = vertexFunction;
        desc.fragmentFunction = fragmentFunction;
        
        _renderPipelineState = [YZMetalRenderingDevice.share.device newRenderPipelineStateWithDescriptor:desc error:nil];
        
        
        NSDictionary *dict = @{
            (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange),
            (id)kCVPixelBufferMetalCompatibilityKey : @(YES)
        };
        _output.videoSettings = dict;
        
        if ([_session canAddOutput:_output]) {
            [_session addOutput:_output];
        }
        
        _session.sessionPreset = AVCaptureSessionPreset640x480;
        [_session commitConfiguration];
        
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, YZMetalRenderingDevice.share.device, nil, &_textureCache);
        [_output setSampleBufferDelegate:self queue:_cameraQueue];
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

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (!_session.isRunning) { return; }
    if (_output != output) { return; }
    if (dispatch_semaphore_wait(_videoSemaphore, DISPATCH_TIME_NOW) != 0) {
        _dropFrames++;
        return;
    }
    CFRetain(sampleBuffer);
    dispatch_async(_cameraRenderQueue, ^{
        [self _processVideoSampleBuffer:sampleBuffer];
        CFRelease(sampleBuffer);
        dispatch_semaphore_signal(self->_videoSemaphore);
    });
}

- (void)_processVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVMetalTextureRef luminanceTextureRef = NULL;
    CVMetalTextureRef chrominanceTextureRef = NULL;
    
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCache, pixelBuffer, nil, MTLPixelFormatR8Unorm, width, height, 0, &luminanceTextureRef);
    CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCache, pixelBuffer, nil, MTLPixelFormatRG8Unorm, width / 2, height / 2, 1, &chrominanceTextureRef);
    
    id<MTLTexture> luminanceTexture = CVMetalTextureGetTexture(luminanceTextureRef);
    id<MTLTexture> chrominanceTexture = CVMetalTextureGetTexture(chrominanceTextureRef);
    CFRelease(luminanceTextureRef);
    CFRelease(chrominanceTextureRef);
    
    MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:height height:width mipmapped:NO];
    desc.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite | MTLTextureUsageRenderTarget;
    id<MTLTexture> newTexture = [YZMetalRenderingDevice.share.device newTextureWithDescriptor:desc];
    
    [self _convertYUVToRGB:luminanceTexture textureUV:chrominanceTexture outputTexture:newTexture];
    
    [self.view newTextureAvailable:newTexture index:0];
}

- (void)_convertYUVToRGB:(id<MTLTexture>)textureY textureUV:(id<MTLTexture>)textureUV outputTexture:(id<MTLTexture>)texture {
    id<MTLCommandBuffer> commandBuffer = [YZMetalRenderingDevice.share.commandQueue commandBuffer];
    
    static const float squareVertices[] = {
        -1.0f, 1.0f, 1.0f, 1.0f, -1.0f,  -1.0f, 1.0f,  -1.0f,
    };

    //NSLog(@"xxxx___%d", sizeof(float) * 8);
    id<MTLBuffer> vertexBuffer = [YZMetalRenderingDevice.share.device newBufferWithBytes:squareVertices length:sizeof(float) * 8 options:MTLResourceStorageModeShared];
    vertexBuffer.label = @"YZVertices";
    
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
    [encoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];
    //[self _renderQuad:textureY textureUV:textureUV outputTexture:texture];
    
    static const float yuvSquareVertices[] = {
        0.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
    };
    id<MTLBuffer> yBuffer = [YZMetalRenderingDevice.share.device newBufferWithBytes:yuvSquareVertices length:sizeof(float) * 8 options:MTLResourceCPUCacheModeDefaultCache];
    yBuffer.label = @"YBuffer";
    [encoder setVertexBuffer:yBuffer offset:0 atIndex:1];
    [encoder setFragmentTexture:textureY atIndex:0];
    
    id<MTLBuffer> uvBuffer = [YZMetalRenderingDevice.share.device newBufferWithBytes:yuvSquareVertices length:sizeof(float) * 8 options:MTLResourceCPUCacheModeDefaultCache];
    uvBuffer.label = @"UVBuffer";
    [encoder setVertexBuffer:uvBuffer offset:0 atIndex:2];
    [encoder setFragmentTexture:textureUV atIndex:1];
    
    //todo
    static const float newtest[] = {
        1.0f, 1.0f,   1.0f,  0,
        0.0f, 0.343, 1.765, 0,
        1.4f, -0.711, 0,     0,
    };
    id<MTLBuffer> uniformBuffer = [YZMetalRenderingDevice.share.device newBufferWithBytes:newtest length:sizeof(float) * 12 options:MTLResourceCPUCacheModeDefaultCache];
    [encoder setFragmentBuffer:uniformBuffer offset:0 atIndex:1];
    
    
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:4];
    [encoder endEncoding];
    
    [commandBuffer commit];
}

#pragma mark - help
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
