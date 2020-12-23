//
//  YZMetalOrientation.m
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/11.
//

#import "YZMetalOrientation.h"

static const simd_float8 defaultVertices = {-1, 1, 1, 1, -1, -1, 1, -1};


static const simd_float8 defaultCoordinates = {0, 0, 1, 0, 0, 1, 1, 1};
static const simd_float8 leftCoordinates = {0, 1, 0, 0, 1, 1, 1, 0};
static const simd_float8 rightCoordinates = {0, 1, 0, 0, 1, 1, 1, 0};


@implementation YZMetalOrientation

+ (simd_float8)defaultVertices {
    return defaultVertices;
}


+ (simd_float8)defaultCoordinates {
    return defaultCoordinates;
}

+ (simd_float8)getCoordinates:(YZOrientation)orientation {
    switch (orientation) {
        case YZOrientationLeft:
            return leftCoordinates;
            break;
            
        default:
            break;
    }
    return defaultCoordinates;
}
@end
