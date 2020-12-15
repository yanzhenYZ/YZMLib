//
//  YZMTKView.h
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/10.
//

#import <MetalKit/MetalKit.h>

@protocol YZMTKViewDelegate <NSObject>

- (void)outputBuffer:(CVPixelBufferRef)buffer;

@end

@class YZTexture;
@interface YZMTKView : MTKView
@property (nonatomic, weak) id<YZMTKViewDelegate> mtkDelegate;

- (void)newTextureAvailable:(id<MTLTexture>)texture index:(NSInteger)index;

@end
