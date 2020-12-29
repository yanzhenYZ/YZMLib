//
//  YZMTKView.h
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/10.
//

#import <MetalKit/MetalKit.h>

typedef NS_ENUM(NSInteger, YZMTKViewFillMode) {
    YZMTKViewFillModeScaleToFill,       // Same as UIViewContentModeScaleToFill
    YZMTKViewFillModeScaleAspectFit,    // Same as UIViewContentModeScaleAspectFit
    YZMTKViewFillModeScaleAspectFill,   // Same as UIViewContentModeScaleAspectFill
};

@class YZTexture;
@interface YZMTKView : MTKView
@property (nonatomic) YZMTKViewFillMode fillMode;

- (void)newTextureAvailable:(id<MTLTexture>)texture index:(NSInteger)index;

- (void)setBackgroundColorRed:(double)red green:(double)green blue:(double)blue alpha:(double)alpha;
@end
