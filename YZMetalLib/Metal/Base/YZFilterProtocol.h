//
//  YZFilterProtocol.h
//  YZMetalLib
//
//  Created by yanzhen on 2021/1/8.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

@protocol YZFilterProtocol <NSObject>

//in render queue
- (void)newTextureAvailable:(id<MTLTexture>)texture commandBuffer:(id<MTLCommandBuffer>)commandBuffer;

@end
