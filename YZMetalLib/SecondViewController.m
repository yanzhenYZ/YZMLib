//
//  SecondViewController.m
//  YZMetalLib
//
//  Created by 闫振 on 2020/12/17.
//

#import "SecondViewController.h"
#import "YZVideoCamera.h"
#import "YZPixelBuffer.h"

@interface SecondViewController ()<YZVideoCameraOutputDelegate>
@property (nonatomic, strong) YZVideoCamera *camera;
@property (weak, nonatomic) IBOutlet UIImageView *player;
@property (nonatomic, strong) CIContext *context;
@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _context = [CIContext contextWithOptions:nil];
    
    YZPixelBuffer *buffer = [[YZPixelBuffer alloc] initWithRender:NO];
    //buffer.delegate = self;
//    [self test002];
    
    _camera = [[YZVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480];
    _camera.buffer = buffer;
    _camera.delegate = self;
    [_camera startRunning];
}

#pragma mark - YZVideoCameraOutputDelegate
- (void)videoCamera:(YZVideoCamera *)camera output:(CMSampleBufferRef)sampleBuffer {
    
}

- (void)outputBuffer:(CVPixelBufferRef)buffer {
    
}

#pragma mark - private
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
@end
