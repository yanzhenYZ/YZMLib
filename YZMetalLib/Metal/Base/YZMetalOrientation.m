//
//  YZMetalOrientation.m
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/11.
//

#import "YZMetalOrientation.h"

float YZColorConversion601Default[] = {
    1.164, 1.164,  1.164, 0.0,
    0.0,   -0.392, 2.017, 0.0,
    1.596, -0.813, 0.0,   0.0,
};

// BT.601 full range (ref: http://www.equasys.de/colorconversion.html)
float YZColorConversion601FullRangeDefault[] = {
    1.0, 1.0,    1.0,   0.0,
    0.0, -0.343, 1.765, 0.0,
    1.4, -0.711, 0.0,   0.0,
};

// BT.709, which is the standard for HDTV.
float YZColorConversion709Default[] = {
    1.164, 1.164,  1.164, 0.0,
    0.0,   -0.213, 2.112, 0.0,
    1.793, -0.533, 0.0,   0.0,
};


float *kYZColorConversion601 = YZColorConversion601Default;
float *kYZColorConversion601FullRange = YZColorConversion601FullRangeDefault;
float *kYZColorConversion709 = YZColorConversion709Default;

static const simd_float8 StandardVertices = {-1, 1, 1, 1, -1, -1, 1, -1};

static const simd_float8 YZNoRotation = {0, 0, 1, 0, 0, 1, 1, 1};
static const simd_float8 YZRotateCounterclockwise = {0, 1, 0, 0, 1, 1, 1, 0};
static const simd_float8 YZRotateClockwise = {1, 0, 1, 1, 0, 0, 0, 1};
static const simd_float8 YZRotate180 = {1, 1, 0, 1, 1, 0, 0, 0};
static const simd_float8 YZFlipHorizontally = {1, 0, 0, 0, 1, 1, 0, 1};
static const simd_float8 YZFlipVertically = {0, 1, 1, 1, 0, 0, 1, 0};
static const simd_float8 YZRotateClockwiseAndFlipVertically = {0, 0, 0, 1, 1, 0, 1, 1};
static const simd_float8 YZRotateClockwiseAndFlipHorizontally = {1, 1, 1, 0, 0, 1, 0, 0};

typedef NS_ENUM(NSInteger, YZRotation) {
    YZRotationNoRotation                         = 0,
    YZRotationRotate180                          = 1,
    YZRotationRotateCounterclockwise             = 2,
    YZRotationRotateClockwise                    = 3,
    YZRotationFlipHorizontally                   = 4,
    YZRotationFlipVertically                     = 5,
    YZRotationRotateClockwiseAndFlipVertically   = 6,
    YZRotationRotateClockwiseAndFlipHorizontally = 7
};

@interface YZMetalOrientation ()
@property (nonatomic) YZOrientation inputOrientation;
@end

@implementation YZMetalOrientation

- (instancetype)init
{
    self = [super init];
    if (self) {
        _inputOrientation = YZOrientationRight;
        _outputOrientation = YZOrientationPortrait;
        _mirror = YES;
    }
    return self;
}

+ (simd_float8)defaultVertices {
    return StandardVertices;
}


+ (simd_float8)defaultTextureCoordinates {
    return YZNoRotation;
}

- (simd_float8)getTextureCoordinates {
    return [self getTextureCoordinates:AVCaptureDevicePositionFront];
}

- (simd_float8)getTextureCoordinates:(AVCaptureDevicePosition)position {
    YZRotation rotation = [self getRotation];
    if (position == AVCaptureDevicePositionBack || !_mirror) {
        return [self getTextureCoordinatesWithRotation:rotation];
    }
    rotation = [self getMirrorRotation:rotation];
    return [self getTextureCoordinatesWithRotation:rotation];
}

- (BOOL)switchWithHeight {
    YZRotation rotation = [self getRotation];
    switch (rotation) {
        case YZRotationNoRotation:
            return NO;
            break;
        case YZRotationRotate180:
            return NO;
            break;
        case YZRotationRotateCounterclockwise:
            return YES;
            break;
        case YZRotationRotateClockwise:
            return YES;
            break;
        case YZRotationFlipHorizontally:
            return NO;
            break;
        case YZRotationFlipVertically:
            return NO;
            break;
        case YZRotationRotateClockwiseAndFlipVertically:
            return YES;
            break;
        case YZRotationRotateClockwiseAndFlipHorizontally:
            return YES;
            break;
        default:
            break;
    }
    return NO;
}


- (void)switchCamera {
    if (_outputOrientation == YZOrientationLeft) {
        _outputOrientation = YZOrientationRight;
    } else if (_outputOrientation == YZOrientationRight) {
        _outputOrientation = YZOrientationLeft;
    }
}
#pragma mark - orientation

- (YZRotation)getRotation {
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
    return rotation;
}

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

- (YZRotation)getMirrorRotation:(YZRotation)rotation {
    switch (rotation) {
        case YZRotationNoRotation:
            return YZRotationFlipHorizontally;
            break;
        case YZRotationRotate180:
            return YZRotationFlipVertically;
            break;
        case YZRotationRotateCounterclockwise:
            return YZRotationRotateClockwiseAndFlipVertically;
            break;
        case YZRotationRotateClockwise:
            return YZRotationRotateClockwiseAndFlipHorizontally;
        default:
            break;
    }
    return rotation;
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
