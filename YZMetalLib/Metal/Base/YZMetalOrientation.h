//
//  YZMetalOrientation.h
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/11.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>

typedef NS_ENUM(NSInteger, YZOrientation) {
    YZOrientationUnknown    = 0,
    YZOrientationPortrait   = 1,
    YZOrientationUpsideDown = 2,
    YZOrientationLeft       = 3,
    YZOrientationRight      = 4
};

@interface YZMetalOrientation : NSObject
@property (nonatomic) YZOrientation inputOrientation;
@property (nonatomic) YZOrientation outputOrientation;

+ (simd_float8)defaultVertices;
+ (simd_float8)defaultCoordinates;


- (simd_float8)getTextureCoordinates;

- (BOOL)switchWithHeight;
- (void)switchCamera;
@end

