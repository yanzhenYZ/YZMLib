//
//  YZFilterProtocol.h
//  YZMetalLib
//
//  Created by yanzhen on 2021/1/8.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

@protocol YZFilterProtocol <NSObject>

- (void)newTextureAvailable:(id<MTLTexture>)texture;

@end
