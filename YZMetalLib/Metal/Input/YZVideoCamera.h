//
//  YZVideoCamera.h
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/9.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "YZMTKView.h"

@class YZVideoCamera;
@protocol YZVideoCameraOutputDelegate <NSObject>

- (void)videoCamera:(YZVideoCamera *)camera output:(CMSampleBufferRef)sampleBuffer;
- (void)outputBuffer:(CVPixelBufferRef)buffer;
@end

@interface YZVideoCamera : NSObject
@property (nonatomic, weak) id<YZVideoCameraOutputDelegate> delegate;
@property (nonatomic, strong) YZMTKView *view;

- (instancetype)initWithSessionPreset:(AVCaptureSessionPreset)preset;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;


- (void)startRunning;
- (void)stopRunning;
@end

