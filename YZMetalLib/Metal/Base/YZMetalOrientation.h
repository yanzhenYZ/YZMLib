//
//  YZMetalOrientation.h
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/11.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, YZOrientation) {
    YZOrientationUnknown            = 0,
    YZOrientationPortrait           = 1,
    YZOrientationPortraitUpsideDown = 2,
    YZOrientationLandscapeLeft      = 3,
    YZOrientationLandscapeRight     = 4
};

@interface YZMetalOrientation : NSObject

+ (const float *)defaultVertices;
+ (const float *)defaultCoordinates;

@end

