//
//  YZMTKView.m
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/10.
//

#import "YZMTKView.h"
#import "YZMetalDevice.h"
#import "YZMetalOrientation.h"
#import "YZShaderTypes.h"

@interface YZMTKView ()<MTKViewDelegate>
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property (nonatomic, strong) id<MTLTexture> texture;
@property (nonatomic, strong) id<MTLBuffer> textureCoordinateBuffer;
@property (nonatomic) CGRect currentBounds;
@property (nonatomic) double red;
@property (nonatomic) double green;
@property (nonatomic) double blue;
@property (nonatomic) double alpha;
@end

@implementation YZMTKView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _configSelf];
        self.currentBounds = self.bounds;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self _configSelf];
    }
    return self;
}

- (void)setFillMode:(YZMTKViewFillMode)fillMode {
    _fillMode = fillMode;
    if (fillMode == YZMTKViewFillModeScaleAspectFill) {
        self.contentMode = (UIViewContentMode)fillMode;
    } else {
        self.contentMode = UIViewContentModeScaleToFill;
    }
}

- (void)setBackgroundColorRed:(double)red green:(double)green blue:(double)blue alpha:(double)alpha {
    
}


-(void)newTextureAvailable:(id<MTLTexture>)texture {
    _texture = texture;
    self.drawableSize = CGSizeMake(texture.width, texture.height);
    [self draw];
}

#pragma mark - MTKViewDelegate
- (void)drawInMTKView:(MTKView *)view {
    if (!view.currentDrawable || !_texture) { return; }
    id<MTLTexture> outTexture = view.currentDrawable.texture;
    
    MTLRenderPassDescriptor *desc = [[MTLRenderPassDescriptor alloc] init];
    desc.colorAttachments[0].texture = outTexture;
    desc.colorAttachments[0].clearColor = MTLClearColorMake(_red, _green, _blue, _alpha);
    desc.colorAttachments[0].storeAction = MTLStoreActionStore;
    desc.colorAttachments[0].loadAction = MTLLoadActionClear;
    
    id<MTLCommandBuffer> commandBuffer = [YZMetalDevice.defaultDevice.commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:desc];
    if (!encoder) {
        NSLog(@"YZMTKView render endcoder Fail");
        return;
    }
    [encoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [encoder setRenderPipelineState:_pipelineState];

    CGFloat w = 1;
    CGFloat h = 1;
    if (_fillMode == YZMTKViewFillModeScaleAspectFit) {//for background color
        CGRect bounds = self.currentBounds;
        CGRect insetRect = AVMakeRectWithAspectRatioInsideRect(self.drawableSize, bounds);
        w = insetRect.size.width / bounds.size.width;
        h = insetRect.size.height / bounds.size.height;
    }
    simd_float8 vertices = {-w, h, w, h, -w, -h, w, -h};
    id<MTLBuffer> positionBuffer = [YZMetalDevice.defaultDevice.device newBufferWithBytes:&vertices length:sizeof(simd_float8) options:MTLResourceCPUCacheModeDefaultCache];
    [encoder setVertexBuffer:positionBuffer offset:0 atIndex:YZVertexIndexPosition];
    
    [encoder setVertexBuffer:_textureCoordinateBuffer offset:0 atIndex:YZVertexIndexTextureCoordinate];
    [encoder setFragmentTexture:_texture atIndex:YZFragmentTextureIndexNormal];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    [encoder endEncoding];
    
    [commandBuffer presentDrawable:view.currentDrawable];
    [commandBuffer commit];
    if (_pixelBuffer) {//YZMTKViewFillModeScaleAspectFit outTexture will contain backColor
        [commandBuffer waitUntilCompleted];
        [_pixelBuffer generatePixelBuffer:_texture];
    }
    _texture = nil;
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}

#pragma mark - private config
- (void)_configSelf {
    _alpha = 1.0;
    
    self.paused = YES;
    self.delegate = self;
    self.framebufferOnly = NO;
    self.enableSetNeedsDisplay = NO;
    self.device = YZMetalDevice.defaultDevice.device;
    self.contentMode = UIViewContentModeScaleToFill;
    _pipelineState = [YZMetalDevice.defaultDevice newRenderPipeline:@"YZInputVertex" fragment:@"YZFragment"];
  
    simd_float8 texture = [YZMetalOrientation defaultTexture];
    _textureCoordinateBuffer = [YZMetalDevice.defaultDevice.device newBufferWithBytes:&texture length:sizeof(simd_float8) options:MTLResourceStorageModeShared];
    _textureCoordinateBuffer.label = @"YZMTKView TextureCoordinateBuffer";
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _currentBounds = self.bounds;
}
@end
