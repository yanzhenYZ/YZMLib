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
@property (nonatomic, strong) YZTexture *texture;
@end

@implementation YZMTKView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
//        self.delegate = self;
        
        
        //self.pipelineState = [self.device newRenderPipelineStateWithDescriptor:desc error:NULL];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.device = YZMetalRenderingDevice.share.device;
        
        self.framebufferOnly = NO;
        self.enableSetNeedsDisplay = NO;
        self.paused = YES;
        
        id<MTLFunction> vertexFunction = [YZMetalRenderingDevice.share.defaultLibrary newFunctionWithName:@"oneInputVertex"];
        id<MTLFunction> fragmentFunction = [YZMetalRenderingDevice.share.defaultLibrary newFunctionWithName:@"passthroughFragment"];
        MTLRenderPipelineDescriptor *desc = [[MTLRenderPipelineDescriptor alloc] init];
        desc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;//bgra
        desc.rasterSampleCount = 1;
        desc.vertexFunction = vertexFunction;
        desc.fragmentFunction = fragmentFunction;
        
        NSError *error = nil;
        MTLAutoreleasedRenderPipelineReflection reflection;
        MTLPipelineOption option = MTLPipelineOptionArgumentInfo | MTLPipelineOptionBufferTypeInfo;
        _pipelineState = [self.device newRenderPipelineStateWithDescriptor:desc options:option reflection:&reflection error:&error];
        if (error) {
            NSLog(@"YZMetalRenderingDevice new renderPipelineState failed: %@", error);
        }
    }
    return self;
}

- (void)newTextureAvailable:(YZTexture *)texture index:(NSInteger)index {
    _texture = texture;
    self.drawableSize = CGSizeMake(texture.texture.width, texture.texture.height);
    [self draw];
    //NSLog(@"1234___%d:%d", texture.texture.width, texture.texture.height);
}
#pragma mark - MTKViewDelegate
- (void)drawRect:(CGRect)rect {
    if (!self.currentDrawable || !_texture) {
        return;
    }
    NSLog(@"1234___1234");
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
    
    NSLog(@"xxxx___%d", sizeof(squareVertices));
    
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
    static const simd_float8 uvSquareVertices[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };
    id<MTLBuffer> yBuffer = [YZMetalRenderingDevice.share.device newBufferWithBytes:uvSquareVertices length:sizeof(simd_float8) options:MTLResourceCPUCacheModeDefaultCache];
    yBuffer.label = @"bgraBuffer";
    [encoder setVertexBuffer:yBuffer offset:0 atIndex:1];
    [encoder setFragmentTexture:_texture.texture atIndex:0];

    
    [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    [encoder endEncoding];
    
    [commandBuffer presentDrawable:self.currentDrawable];
    [commandBuffer commit];
    _texture = nil;
}

- (void)drawInMTKView:(MTKView *)view {
    NSLog(@"1234");
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}
@end
