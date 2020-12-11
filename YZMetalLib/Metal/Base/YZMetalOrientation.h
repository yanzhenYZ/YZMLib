//
//  YZMetalOrientation.h
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/11.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, YZOrientation) {
    YZOrientationUnknown    = 0,
    YZOrientationPortrait   = 1,
    YZOrientationUpsideDown = 2,
    YZOrientationLeft       = 3,
    YZOrientationRight      = 4
};

@interface YZMetalOrientation : NSObject

+ (const float *)defaultVertices;

+ (const float *)defaultCoordinates;
+ (const float *)getCoordinates:(YZOrientation)orientation;
@end

