//
//  FirstViewController.m
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/8.
//

#import "FirstViewController.h"
#import "YZVideoCamera.h"
#import "YZMTKView.h"
#import "YZBrightness.h"

@interface FirstViewController ()<YZVideoCameraOutputDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *player;
@property (weak, nonatomic) IBOutlet YZMTKView *mtkView;
@property (nonatomic, strong) YZVideoCamera *camera;
@property (nonatomic, strong) YZMTKView *mtkView2;
@property (nonatomic, strong) CIContext *context;

@property (nonatomic, strong) YZBrightness *brightness;
@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

//    [self test_001];
    
    [self test003];
}

- (void)test003 {
    _camera = [[YZVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480];
    
    _mtkView2 = [[YZMTKView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    [self.view addSubview:_mtkView2];
    
    _brightness = [[YZBrightness alloc] init];
    
    _camera.brightness = _brightness;
    _brightness.view = _mtkView2;
    
    _camera.delegate = self;
    [_camera startRunning];
}

- (void)test002 {
    _camera = [[YZVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480];
    
    _mtkView2 = [[YZMTKView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    [self.view addSubview:_mtkView2];
    _camera.view = _mtkView2;
    
    _camera.delegate = self;
    [_camera startRunning];
}

- (void)test_001 {

    _camera = [[YZVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480];
    _camera.view = _mtkView;
    _camera.delegate = self;
    [_camera startRunning];
    
}

- (void)showPixelBuffer:(CVPixelBufferRef)pixel {
    CVPixelBufferRetain(pixel);
    CIImage *ciImage = [CIImage imageWithCVImageBuffer:pixel];
    size_t width = CVPixelBufferGetWidth(pixel);
    size_t height = CVPixelBufferGetHeight(pixel);
    CGImageRef videoImageRef = [_context createCGImage:ciImage fromRect:CGRectMake(0, 0, width, height)];
    UIImage *image = [UIImage imageWithCGImage:videoImageRef];
    CGImageRelease(videoImageRef);
    CVPixelBufferRelease(pixel);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.player.image = image;
    });
}

#pragma mark - YZVideoCameraOutputDelegate
- (void)videoCamera:(YZVideoCamera *)camera output:(CMSampleBufferRef)sampleBuffer {
    [self showPixelBuffer:CMSampleBufferGetImageBuffer(sampleBuffer)];
}

@end
