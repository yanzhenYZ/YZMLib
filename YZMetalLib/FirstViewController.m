//
//  FirstViewController.m
//  YZMetalLib
//
//  Created by 闫振 on 2020/12/8.
//

#import "FirstViewController.h"
#import "YZVideoCamera.h"

@interface FirstViewController ()<YZVideoCameraOutputDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *player;
@property (nonatomic, strong) YZVideoCamera *camera;


@property (nonatomic, strong) CIContext *context;

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _context = [CIContext contextWithOptions:nil];
    
    _camera = [[YZVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480];
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
