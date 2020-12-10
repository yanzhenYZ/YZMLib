//
//  YZMetalRenderingDevice.h
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/9.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "YZShaderUniform.h"

@interface YZMetalRenderingDevice : NSObject
@property (nonatomic, strong, readonly) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLRenderPipelineState> renderPipelineState;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLLibrary> defaultLibrary;

+ (instancetype)share;

- (void)generateRenderPipelineState:(BOOL)fullYUV;
- (YZShaderUniform *)getRenderUniform;
@end


