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
#import "YZNewPixelBuffer.h"


@interface FirstViewController ()<YZVideoCameraOutputDelegate, YZNewPixelBufferDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *player;
@property (weak, nonatomic) IBOutlet YZMTKView *mtkView;
@property (nonatomic, strong) YZVideoCamera *camera;
@property (nonatomic, strong) YZMTKView *mtkView2;
@property (nonatomic, strong) CIContext *context;
@property (weak, nonatomic) IBOutlet UISegmentedControl *fillSegmentControll;

@property (nonatomic, strong) YZBrightness *brightness;
@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    simd_float3 aa = {1, 2, 3};
    
    _context = [CIContext contextWithOptions:nil];
    
    
    _fillSegmentControll.selectedSegmentIndex = 1;
    _mtkView.fillMode = YZMTKViewFillModeScaleAspectFit;
    
    [self test003];
}

- (void)test003 {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarDidChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
    _camera = [[YZVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480];
    _camera.outputOrientation = UIApplication.sharedApplication.statusBarOrientation;
    _brightness = [[YZBrightness alloc] init];
    
    YZNewPixelBuffer *pixelBuffer = [[YZNewPixelBuffer alloc] initWithSize:CGSizeMake(360, 640)];
    pixelBuffer.delegate = self;
    
    [_camera addFilter:_brightness];
    [_brightness addFilter:pixelBuffer];
    
    //2
//    _mtkView.filter = pixelBuffer;
//    _camera.filter = _brightness;
//    _brightness.filter = _mtkView;
    
    //1
//    _camera.filter = _mtkView;
    
    _camera.delegate = self;
    [_camera startRunning];
}

- (IBAction)fillModel:(UISegmentedControl *)sender {
    _mtkView.fillMode = (YZMTKViewFillMode)sender.selectedSegmentIndex;
}

- (IBAction)switchCamera:(id)sender {
    [_camera switchCamera];
}

- (IBAction)seset:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        _camera.preset = AVCaptureSessionPreset640x480;
    } else if (sender.selectedSegmentIndex == 1) {
        _camera.preset = AVCaptureSessionPreset1280x720;
    } 
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    [_camera switchCamera];
//    if (_camera.videoMirrored) {
//        _camera.videoMirrored = NO;
//    } else {
//        _camera.videoMirrored = YES;
//    }
}


- (IBAction)beautyValueChange:(UISlider *)sender {
    _brightness.beautyLevel = sender.value;
}

- (IBAction)brightValueChange:(UISlider *)sender {
    _brightness.brightLevel = sender.value;
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

#pragma mark - YZPixelBufferDelegate
-(void)outputPixelBuffer:(CVPixelBufferRef)buffer {
    [self showPixelBuffer:buffer];
}

#pragma mark - YZVideoCameraOutputDelegate
- (void)videoCamera:(YZVideoCamera *)camera output:(CMSampleBufferRef)sampleBuffer {
    //[self showPixelBuffer:CMSampleBufferGetImageBuffer(sampleBuffer)];
}


- (void)statusBarDidChanged:(NSNotification *)note {
//    NSLog(@"UIApplicationDidChangeStatusBarOrientationNotification UserInfo: %@", note.userInfo);
    UIInterfaceOrientation statusBar = [[UIApplication sharedApplication] statusBarOrientation];
    _camera.outputOrientation = statusBar;
}
    
- (void)dealloc {
    NSLog(@"--- FirstViewController Dealloc");
}
@end
