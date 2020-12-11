//
//  YZMetalDevice.h
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/11.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

@interface YZMetalDevice : NSObject
@property (nonatomic, strong, readonly) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLRenderPipelineState> renderPipelineState;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLLibrary> defaultLibrary;

+ (instancetype)defaultDevice;

- (void)generateRenderPipelineState:(BOOL)fullYUV;
@end

