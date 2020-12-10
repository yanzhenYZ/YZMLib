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
        _commandQueue = [_device newCommandQueue];
        //BOOL support = MPSSupportsMTLDevice(_device);
        NSBundle *bundle = [NSBundle bundleForClass:self.class];
        //you must have a metal file in project
        NSString *path = [bundle pathForResource:@"default" ofType:@"metallib"];
        if (!path) {
            NSLog(@"YZMetalRenderingDevice make path error");
        } else {
            NSError *error = nil;
            _defaultLibrary = [_device newLibraryWithFile:path error:&error];
            if (error) {
                NSLog(@"YZMetalRenderingDevice newLibrary fail:%@", error.localizedDescription);
            }
        }
    }
    return self;
}

#pragma mark - public
- (void)generateRenderPipelineState:(BOOL)fullYUV; {
    
}
@end
