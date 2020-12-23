//
//  YZMetalOrientation.m
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/11.
//

#import "YZMetalOrientation.h"

static const simd_float8 defaultVertices = {-1, 1, 1, 1, -1, -1, 1, -1};

static const float defaultCoordinates[] = {
    0.0, 0.0,
    1.0,  0.0,
    0.0,  1.0,
    1.0,  1.0,
};

static const float leftCoordinates[] = {
    0.0f, 1.0f,
    0.0f, 0.0f,
    1.0f, 1.0f,
    1.0f, 0.0f,
};

static const float rightCoordinates[] = {
    0.0f, 1.0f,
    0.0f, 0.0f,
    1.0f, 1.0f,
    1.0f, 0.0f,
};


@implementation YZMetalOrientation

+ (simd_float8)defaultVertices {
    return defaultVertices;
}

+ (const float *)defaultCoordinates {
    return defaultCoordinates;
}

+ (const float *)getCoordinates:(YZOrientation)orientation {
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
