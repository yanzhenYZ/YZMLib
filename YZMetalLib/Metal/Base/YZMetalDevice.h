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

+ (instancetype)defaultDevice;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

#pragma mark - metal

- (id<MTLCommandBuffer>)commandBuffer;
+ (MTLRenderPassDescriptor *)newRenderPassDescriptor:(id<MTLTexture>)texture;
- (id<MTLRenderPipelineState>)newRenderPipeline:(NSString *)vertex fragment:(NSString *)fragment;

#pragma mark - semaphore
+ (void)semaphoreSignal;
+ (intptr_t)semaphoreWaitNow;
+ (void)semaphoreWaitForever;
@end

