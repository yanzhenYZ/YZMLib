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
@property (nonatomic, strong) id<MTLBuffer> positionBuffer;
@property (nonatomic, strong) id<MTLBuffer> textureCoordinateBuffer;

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
    self.contentMode = (UIViewContentMode)fillMode;
}

- (void)setBackgroundColorRed:(double)red green:(double)green blue:(double)blue alpha:(double)alpha {
    
}

- (void)newTextureAvailable:(id<MTLTexture>)texture index:(NSInteger)index {
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
    }
    [encoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [encoder setRenderPipelineState:_pipelineState];
    [encoder setVertexBuffer:_positionBuffer offset:0 atIndex:YZMTKViewVertexIndexPosition];
    
#if 1
    simd_float8 coordinates = {0, 0, 1, 0, 0, 1, 1, 1};
#else
    simd_float8 coordinates = [YZMetalOrientation defaultCoordinates];
#endif
    id<MTLBuffer> textureCoordinateBuffer = [YZMetalDevice.defaultDevice.device newBufferWithBytes:&coordinates length:sizeof(simd_float8) options:MTLResourceStorageModeShared];
    textureCoordinateBuffer.label = @"YZMTKView TextureCoordinateBuffer";
    [encoder setVertexBuffer:textureCoordinateBuffer offset:0 atIndex:YZMTKViewVertexIndexTextureCoordinate];
    [encoder setFragmentTexture:_texture atIndex:YZMTKViewFragmentIndexTexture];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    [encoder endEncoding];
    
    [commandBuffer presentDrawable:view.currentDrawable];
    [commandBuffer commit];
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
    _pipelineState = [YZMetalDevice.defaultDevice newRenderPipeline:@"YZMTKViewInputVertex" fragment:@"YZMTKViewFragment"];
    
    simd_float8 vertices = [YZMetalOrientation defaultVertices];
    _positionBuffer = [YZMetalDevice.defaultDevice.device newBufferWithBytes:&vertices length:sizeof(simd_float8) options:MTLResourceStorageModeShared];
    _positionBuffer.label = @"YZMTKView PositionBuffer";
    
    /*
    simd_float8 coordinates = [YZMetalOrientation defaultCoordinates];
    _textureCoordinateBuffer = [YZMetalDevice.defaultDevice.device newBufferWithBytes:&coordinates length:sizeof(simd_float8) options:MTLResourceStorageModeShared];
    _textureCoordinateBuffer.label = @"YZMTKView TextureCoordinateBuffer";*/
}
@end
