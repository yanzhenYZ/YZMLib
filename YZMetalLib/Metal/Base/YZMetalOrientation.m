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

+ (simd_float8)defaultVertices {
    return StandardVertices;
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

#pragma mark - orientation

- (simd_float8)getRCoordinates:(YZRotation)rotation {
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

- (void)cal {
    switch (_inputOrientation) {
        case YZOrientationPortrait:
            [self getPortrait];
            break;
        case YZOrientationUpsideDown:
            [self getUpsideDown];
            break;
        case YZOrientationLeft:
            [self getLeft];
            break;
        case YZOrientationRight:
            [self getRight];
            break;
        default:
            break;
    }
}

- (YZRotation)getPortrait {
    switch (_outputOrientation) {
        case YZOrientationPortrait:
            return YZRotationNoRotation;
            break;
        case YZOrientationUpsideDown:
            NSLog(@"IN_YZOrientationUpsideDown");
            break;
        case YZOrientationLeft:
            NSLog(@"IN_YZOrientationLeft");
            break;
        case YZOrientationRight:
            NSLog(@"IN_YZOrientationRight");
            break;
        default:
            return YZRotationNoRotation;
            break;
    }
    return YZRotationNoRotation;
}

- (void)getUpsideDown {
    switch (_outputOrientation) {
        case YZOrientationPortrait:
            NSLog(@"IN_YZOrientationPortrait");
            break;
        case YZOrientationUpsideDown:
            NSLog(@"IN_YZOrientationUpsideDown");
            break;
        case YZOrientationLeft:
            NSLog(@"IN_YZOrientationLeft");
            break;
        case YZOrientationRight:
            NSLog(@"IN_YZOrientationRight");
            break;
        default:
            break;
    }
}

- (void)getLeft {
    switch (_outputOrientation) {
        case YZOrientationPortrait:
            NSLog(@"IN_YZOrientationPortrait");
            break;
        case YZOrientationUpsideDown:
            NSLog(@"IN_YZOrientationUpsideDown");
            break;
        case YZOrientationLeft:
            NSLog(@"IN_YZOrientationLeft");
            break;
        case YZOrientationRight:
            NSLog(@"IN_YZOrientationRight");
            break;
        default:
            break;
    }
}

- (void)getRight {
    switch (_outputOrientation) {
        case YZOrientationPortrait:
            NSLog(@"IN_YZOrientationPortrait");
            break;
        case YZOrientationUpsideDown:
            NSLog(@"IN_YZOrientationUpsideDown");
            break;
        case YZOrientationLeft:
            NSLog(@"IN_YZOrientationLeft");
            break;
        case YZOrientationRight:
            NSLog(@"IN_YZOrientationRight");
            break;
        default:
            break;
    }
}
@end
