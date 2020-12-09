//
//  YZVideoCamera.h
//  YZMetalLib
//
//  Created by 闫振 on 2020/12/9.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class YZVideoCamera;
@protocol YZVideoCameraOutputDelegate <NSObject>

- (void)videoCamera:(YZVideoCamera *)camera output:(CMSampleBufferRef)sampleBuffer;

@end

@interface YZVideoCamera : NSObject
@property (nonatomic, weak) id<YZVideoCameraOutputDelegate> delegate;

- (instancetype)initWithSessionPreset:(AVCaptureSessionPreset)preset;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;


- (void)startRunning;
- (void)stopRunning;
@end

