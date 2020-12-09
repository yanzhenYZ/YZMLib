//
//  YZVideoCamera.m
//  YZMetalLib
//
//  Created by 闫振 on 2020/12/9.
//

#import "YZVideoCamera.h"

@interface YZVideoCamera ()<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDevice *camera;
@property (nonatomic, strong) AVCaptureDeviceInput *input;
@property (nonatomic, strong) AVCaptureVideoDataOutput *output;
@property (nonatomic, copy) AVCaptureSessionPreset preset;

@property (nonatomic, assign) BOOL fullYUVRange;

@end

@implementation YZVideoCamera {
    dispatch_queue_t _cameraQueue;
    dispatch_semaphore_t _videoSemaphore;
}

- (instancetype)initWithSessionPreset:(AVCaptureSessionPreset)preset
{
    self = [super init];
    if (self) {
        _cameraQueue = dispatch_queue_create("com.yanzhen.video.camera.queue", 0);
        _videoSemaphore = dispatch_semaphore_create(1);
        _preset = preset;
        [self _configVideoSession];
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
        return;
    }
    //add a thread
    if ([_delegate respondsToSelector:@selector(videoCamera:output:)]) {
        [_delegate videoCamera:self output:sampleBuffer];
    }
    dispatch_semaphore_signal(_videoSemaphore);
}

#pragma mark - private

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

//todo new
+ (AVCaptureDevice *)defaultFrontDevice {
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
@end
