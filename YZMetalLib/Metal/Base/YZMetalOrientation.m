//
//  YZMetalOrientation.m
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/11.
//

#import "YZMetalOrientation.h"

static const float defaultVertices[] = {
    -1.0, 1.0,
    1.0,  1.0,
    -1.0, -1.0,
    1.0,  -1.0,
};

static const float defaultCoordinates[] = {
    0.0, 0.0,
    1.0,  0.0,
    0.0,  1.0,
    1.0,  1.0,
};


@implementation YZMetalOrientation

+ (const float *)defaultVertices {
    return defaultVertices;
}

+ (const float *)defaultCoordinates {
    return defaultCoordinates;
}
@end
