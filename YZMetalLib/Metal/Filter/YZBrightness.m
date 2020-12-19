//
//  YZBrightness.m
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/19.
//

#import "YZBrightness.h"
#import <Metal/Metal.h>

@interface YZBrightness ()

@end

@implementation YZBrightness

- (void)newTextureAvailable:(id<MTLTexture>)texture index:(NSInteger)index {
    [self.view newTextureAvailable:texture index:index];
}
@end
