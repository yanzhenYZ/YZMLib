//
//  YZMetalDevice.m
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/11.
//

#import "YZMetalDevice.h"

@interface YZMetalDevice ()

@end

@implementation YZMetalDevice
static id _metalDevice;

+ (instancetype)defaultDevice
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _metalDevice = [[self alloc] init];
    });
    return _metalDevice;
}

+(instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _metalDevice = [super allocWithZone:zone];
    });
    return _metalDevice;
}

- (id)copyWithZone:(NSZone *)zone
{
    return _metalDevice;
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
            NSLog(@"YZMetalDevice make path error");
        } else {
            NSError *error = nil;
            _defaultLibrary = [_device newLibraryWithFile:path error:&error];
            if (error) {
                NSLog(@"YZMetalDevice newLibrary fail:%@", error.localizedDescription);
            }
        }
    }
    return self;
}

#pragma mark - pipeline

- (id<MTLRenderPipelineState>)newRenderPipeline:(NSString *)vertex fragment:(NSString *)fragment {
    id<MTLFunction> vertexFunction = [_defaultLibrary newFunctionWithName:vertex];
    id<MTLFunction> fragmentFunction = [_defaultLibrary newFunctionWithName:fragment];
    MTLRenderPipelineDescriptor *desc = [[MTLRenderPipelineDescriptor alloc] init];
    desc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;//bgra
    desc.rasterSampleCount = 1;
    desc.vertexFunction = vertexFunction;
    desc.fragmentFunction = fragmentFunction;
    
    NSError *error = nil;
    id<MTLRenderPipelineState> pipeline = [_device newRenderPipelineStateWithDescriptor:desc error:&error];
    if (error) {
        NSLog(@"YZMetalRenderingDevice new renderPipelineState failed: %@", error);
    }
    return pipeline;
}
@end
