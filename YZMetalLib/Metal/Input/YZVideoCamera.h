//
//  YZVideoCamera.h
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/9.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "YZMetalOutput.h"

@class YZVideoCamera;
@protocol YZVideoCameraOutputDelegate <NSObject>

- (void)videoCamera:(YZVideoCamera *)camera output:(CMSampleBufferRef)sampleBuffer;

@end

@interface YZVideoCamera : YZMetalOutput//use filter
@property (nonatomic, weak) id<YZVideoCameraOutputDelegate> delegate;
/**default is 15*/
@property (nonatomic, assign) int32_t frameRate;
@property (nonatomic, copy) AVCaptureSessionPreset preset;

/** default is UIInterfaceOrientationPortrait */
@property (nonatomic) UIInterfaceOrientation outputOrientation;

/**
 default is YES.
 Only use for AVCaptureDevicePositionFront
 */
@property (nonatomic) BOOL videoMirrored;

- (instancetype)initWithSessionPreset:(AVCaptureSessionPreset)preset;
- (instancetype)initWithSessionPreset:(AVCaptureSessionPreset)preset position:(AVCaptureDevicePosition)position;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;


- (void)startRunning;
- (void)stopRunning;

- (void)switchCamera;
@end

