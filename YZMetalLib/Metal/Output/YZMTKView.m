//
//  YZMTKView.m
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/10.
//

#import "YZMTKView.h"
#import "YZMetalRenderingDevice.h"
#import "YZTexture.h"

@interface YZMTKView ()<MTKViewDelegate>
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property (nonatomic, strong) id<MTLTexture> texture;
@end

@implementation YZMTKView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _config];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self _config];
    }
    return self;
}

- (void)_config {
    
    self.framebufferOnly = NO;
    self.autoResizeDrawable = YES;
    
    self.device = YZMetalRenderingDevice.share.device;

    
    id<MTLFunction> vertexFunction = [YZMetalRenderingDevice.share.defaultLibrary newFunctionWithName:@"oneInputVertex"];
    id<MTLFunction> fragmentFunction = [YZMetalRenderingDevice.share.defaultLibrary newFunctionWithName:@"passthroughFragment"];
    MTLRenderPipelineDescriptor *desc = [[MTLRenderPipelineDescriptor alloc] init];
    desc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;//bgra
    desc.rasterSampleCount = 1;
    desc.vertexFunction = vertexFunction;
    desc.fragmentFunction = fragmentFunction;
    
    NSError *error = nil;
    _pipelineState = [self.device newRenderPipelineStateWithDescriptor:desc error:&error];
    if (error) {
        NSLog(@"YZMetalRenderingDevice new renderPipelineState failed: %@", error);
    }
    
    self.enableSetNeedsDisplay = NO;
    self.paused = YES;
    
    self.delegate = self;
}

- (void)newTextureAvailable:(id<MTLTexture>)texture index:(NSInteger)index {
    _texture = texture;
    self.drawableSize = CGSizeMake(texture.width, texture.height);
    [self draw];
}

#pragma mark - MTKViewDelegate
- (void)drawInMTKView:(MTKView *)view {
    if (!self.currentDrawable || !_texture) {
        return;
    }
    id<MTLCommandBuffer> commandBuffer = [YZMetalRenderingDevice.share.commandQueue commandBuffer];
    YZTexture *outTexture = [[YZTexture alloc] initWithOrientation:UIInterfaceOrientationPortrait texture:self.currentDrawable.texture];
    
    static const float squareVertices[] = {
        -1.0f, 1.0f,
        1.0f, 1.0f,
        -1.0f,  -1.0f,
        1.0f,  -1.0f,
    };
    id<MTLBuffer> vertexBuffer = [YZMetalRenderingDevice.share.device newBufferWithBytes:squareVertices length:sizeof(squareVertices) options:MTLResourceCPUCacheModeDefaultCache];
    vertexBuffer.label = @"YZVertices02";
    
    MTLRenderPassDescriptor *desc = [[MTLRenderPassDescriptor alloc] init];
    desc.colorAttachments[0].texture = outTexture.texture;
    desc.colorAttachments[0].clearColor = MTLClearColorMake(1, 0, 0, 1);
    desc.colorAttachments[0].storeAction = MTLStoreActionStore;
    desc.colorAttachments[0].loadAction = MTLLoadActionClear;
    
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:desc];
    if (!encoder) {
        NSLog(@"YZVideoCamera render endcoder Fail");
    }
    [encoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [encoder setRenderPipelineState:_pipelineState];
    [encoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];
    //texture
    static const float uvSquareVertices[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };
    id<MTLBuffer> yBuffer = [YZMetalRenderingDevice.share.device newBufferWithBytes:uvSquareVertices length:sizeof(float) * 8 options:MTLResourceCPUCacheModeDefaultCache];
    yBuffer.label = @"bgraBuffer";
    [encoder setVertexBuffer:yBuffer offset:0 atIndex:1];
    [encoder setFragmentTexture:_texture atIndex:0];

    
    [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    [encoder endEncoding];
    
    [commandBuffer presentDrawable:view.currentDrawable];
    [commandBuffer commit];
    _texture = nil;
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}
@end
