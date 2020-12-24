//
//  YZMetalOrientation.m
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/11.
//

#import "YZMetalOrientation.h"

static const simd_float8 StandardVertices = {-1, 1, 1, 1, -1, -1, 1, -1};

static const simd_float8 YZNoRotation = {0, 0, 1, 0, 0, 1, 1, 1};
static const simd_float8 YZRotateCounterclockwise = {0, 1, 0, 0, 1, 1, 1, 0};
static const simd_float8 YZRotateClockwise = {1, 0, 1, 1, 0, 0, 0, 1};
static const simd_float8 YZRotate180 = {1, 1, 0, 1, 1, 0, 0, 0};
static const simd_float8 YZFlipHorizontally = {1, 0, 0, 0, 1, 1, 0, 1};
static const simd_float8 YZFlipVertically = {0, 1, 1, 1, 0, 0, 1, 0};
static const simd_float8 YZRotateClockwiseAndFlipVertically = {0, 0, 0, 1, 1, 0, 1, 1};
static const simd_float8 YZRotateClockwiseAndFlipHorizontally = {1, 1, 1, 0, 0, 1, 0, 0};


static const simd_float8 defaultCoordinates = {0, 0, 1, 0, 0, 1, 1, 1};
static const simd_float8 leftCoordinates = {0, 1, 0, 0, 1, 1, 1, 0};

typedef NS_ENUM(NSInteger, YZRotation) {
    YZRotationNoRotation                         = 0,
    YZRotationRotateCounterclockwise             = 1,
    YZRotationRotateClockwise                    = 2,
    YZRotationRotate180                          = 3,
    YZRotationFlipHorizontally                   = 4,
    YZRotationFlipVertically                     = 5,
    YZRotationRotateClockwiseAndFlipVertically   = 6,
    YZRotationRotateClockwiseAndFlipHorizontally = 7
};

@implementation YZMetalOrientation

- (instancetype)init
{
    self = [super init];
    if (self) {
        _inputOrientation = YZOrientationRight;
        _outputOrientation = YZOrientationPortrait;
    }
    return self;
}

+ (simd_float8)defaultVertices {
    return StandardVertices;
}


+ (simd_float8)defaultCoordinates {
    return YZNoRotation;
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

- (simd_float8)getTextureCoordinates {
    YZRotation rotation = YZRotationNoRotation;
    switch (_inputOrientation) {
        case YZOrientationPortrait:
            rotation = [self getPortraitRotation];
            break;
        case YZOrientationUpsideDown:
            rotation = [self getUpsideDownRotation];
            break;
        case YZOrientationLeft:
            rotation = [self getLeftRotation];
            break;
        case YZOrientationRight:
            rotation = [self getRightRotation];
            break;
        default:
            break;
    }
    return [self getTextureCoordinatesWithRotation:rotation];
}

#pragma mark - orientation

- (simd_float8)getTextureCoordinatesWithRotation:(YZRotation)rotation {
    switch (rotation) {
        case YZRotationNoRotation:
            return YZNoRotation;
            break;
        case YZRotationRotateCounterclockwise:
            return YZRotateCounterclockwise;
            break;
        case YZRotationRotateClockwise:
            return YZRotateClockwise;
            break;
        case YZRotationRotate180:
            return YZRotate180;
            break;
        case YZRotationFlipHorizontally:
            return YZFlipHorizontally;
            break;
        case YZRotationFlipVertically:
            return YZFlipVertically;
            break;
        case YZRotationRotateClockwiseAndFlipVertically:
            return YZRotateClockwiseAndFlipVertically;
            break;
        case YZRotationRotateClockwiseAndFlipHorizontally:
            return YZRotateClockwiseAndFlipHorizontally;
            break;
        default:
            break;
    }
    return YZRotationNoRotation;
}

- (YZRotation)getPortraitRotation {
    switch (_outputOrientation) {
        case YZOrientationPortrait:
            return YZRotationNoRotation;
            break;
        case YZOrientationUpsideDown:
            return YZRotationRotate180;
            break;
        case YZOrientationLeft:
            return YZRotationRotateCounterclockwise;
            break;
        case YZOrientationRight:
            return YZRotationRotateClockwise;
            break;
        default:
            return YZRotationNoRotation;
            break;
    }
    return YZRotationNoRotation;
}

- (YZRotation)getUpsideDownRotation {
    switch (_outputOrientation) {
        case YZOrientationPortrait:
            return YZRotationRotate180;
            break;
        case YZOrientationUpsideDown:
            return YZRotationNoRotation;
            break;
        case YZOrientationLeft:
            return YZRotationRotateClockwise;
            break;
        case YZOrientationRight:
            return YZRotationRotateCounterclockwise;
            break;
        default:
            break;
    }
    return YZRotationNoRotation;
}

- (YZRotation)getLeftRotation {
    switch (_outputOrientation) {
        case YZOrientationPortrait:
            return YZRotationRotateClockwise;
            break;
        case YZOrientationUpsideDown:
            return YZRotationRotateCounterclockwise;
            break;
        case YZOrientationLeft:
            return YZRotationNoRotation;
            break;
        case YZOrientationRight:
            return YZRotationRotate180;
            break;
        default:
            break;
    }
    return YZRotationNoRotation;
}

- (YZRotation)getRightRotation {
    switch (_outputOrientation) {
        case YZOrientationPortrait:
            return YZRotationRotateCounterclockwise;
            break;
        case YZOrientationUpsideDown:
            return YZRotationRotateClockwise;
            break;
        case YZOrientationLeft:
            return YZRotationRotate180;
            break;
        case YZOrientationRight:
            return YZRotationNoRotation;
            break;
        default:
            break;
    }
    return YZRotationNoRotation;
}
@end
