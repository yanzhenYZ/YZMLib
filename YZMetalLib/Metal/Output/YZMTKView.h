//
//  YZMTKView.h
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/10.
//

#import <MetalKit/MetalKit.h>
#import "YZFilterProtocol.h"
#import "YZPixelBuffer.h"

typedef NS_ENUM(NSInteger, YZMTKViewFillMode) {
    YZMTKViewFillModeScaleToFill,       // Same as UIViewContentModeScaleToFill
    YZMTKViewFillModeScaleAspectFit,    // Same as UIViewContentModeScaleAspectFit
    YZMTKViewFillModeScaleAspectFill,   // Same as UIViewContentModeScaleAspectFill
};

@class YZTexture;
@interface YZMTKView : MTKView<YZFilterProtocol>
@property (nonatomic) YZMTKViewFillMode fillMode;
@property (nonatomic, strong) YZPixelBuffer *pixelBuffer;

- (void)setBackgroundColorRed:(double)red green:(double)green blue:(double)blue alpha:(double)alpha;
@end
