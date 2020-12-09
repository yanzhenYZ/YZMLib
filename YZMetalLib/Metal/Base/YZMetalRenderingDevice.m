//
//  YZMetalRenderingDevice.m
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/9.
//

#import "YZMetalRenderingDevice.h"

@implementation YZMetalRenderingDevice
static id _share;
+ (instancetype)share
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _share = [[self alloc] init];
    });
    return _share;
}

+(instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _share = [super allocWithZone:zone];
    });
    return _share;
}

- (id)copyWithZone:(NSZone *)zone
{
    return _share;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _device = MTLCreateSystemDefaultDevice();
    }
    return self;
}

@end
