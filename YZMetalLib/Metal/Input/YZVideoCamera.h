//
//  YZVideoCamera.h
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/9.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "YZMTKView.h"
#import "YZBrightness.h"
#import "YZMetalOrientation.h"

@class YZVideoCamera;
@protocol YZVideoCameraOutputDelegate <NSObject>

- (void)videoCamera:(YZVideoCamera *)camera output:(CMSampleBufferRef)sampleBuffer;

@end

@interface YZVideoCamera : NSObject
@property (nonatomic, weak) id<YZVideoCameraOutputDelegate> delegate;
@property (nonatomic, strong) YZBrightness *brightness;
@property (nonatomic) YZOrientation outputOrientation;
@property (nonatomic, strong) YZMTKView *view;

- (instancetype)initWithSessionPreset:(AVCaptureSessionPreset)preset orientation:(YZMetalOrientation *)orientation;
- (instancetype)initWithSessionPreset:(AVCaptureSessionPreset)preset orientation:(YZMetalOrientation *)orientation position:(AVCaptureDevicePosition)position;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;


- (void)startRunning;
- (void)stopRunning;

- (void)switchCamera;
@end

