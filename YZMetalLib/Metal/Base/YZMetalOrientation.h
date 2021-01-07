//
//  YZMetalOrientation.h
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/11.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <MetalKit/MetalKit.h>

typedef NS_ENUM(NSInteger, YZOrientation) {
    YZOrientationUnknown    = 0,
    YZOrientationPortrait   = 1,
    YZOrientationUpsideDown = 2,
    YZOrientationLeft       = 3,
    YZOrientationRight      = 4
};

@interface YZMetalOrientation : NSObject
@property (nonatomic) YZOrientation outputOrientation;
/**
 default is YES.
 Only use for AVCaptureDevicePositionFront
 */
@property (nonatomic) BOOL mirror;

+ (simd_float8)defaultVertices;
+ (simd_float8)defaultTexture;


- (simd_float8)getTextureCoordinates;
- (simd_float8)getTextureCoordinates:(AVCaptureDevicePosition)position;

- (BOOL)switchWithHeight;
- (void)switchCamera;
@end

