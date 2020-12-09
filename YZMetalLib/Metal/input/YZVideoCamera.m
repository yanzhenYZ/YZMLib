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

@interface YZVideoCamera ()<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDevice *camera;
@property (nonatomic, strong) AVCaptureDeviceInput *input;
@property (nonatomic, strong) AVCaptureVideoDataOutput *output;
@property (nonatomic, copy) AVCaptureSessionPreset preset;

@property (nonatomic, assign) CVMetalTextureCacheRef textureCache;

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
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVMetalTextureRef texture = NULL;
    id <MTLTexture> textureY = NULL;
    id <MTLTexture> textureUV = NULL;
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
        [_output setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    } else {
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
