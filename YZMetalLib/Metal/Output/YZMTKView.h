//
//  YZMTKView.h
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/10.
//

#import <MetalKit/MetalKit.h>

@class YZTexture;
@interface YZMTKView : MTKView
- (void)newTextureAvailable:(id<MTLTexture>)texture index:(NSInteger)index;
@end
