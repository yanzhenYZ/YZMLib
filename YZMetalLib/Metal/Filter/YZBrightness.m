//
//  YZBrightness.m
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/19.
//

#import "YZBrightness.h"
#import <Metal/Metal.h>
#import "YZMetalDevice.h"
#import "YZShaderTypes.h"
#import "YZMetalOrientation.h"

@interface YZBrightness ()
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property (nonatomic, strong) id<MTLBuffer> positionBuffer;
@property (nonatomic, strong) id<MTLBuffer> textureBuffer;
@end

@implementation YZBrightness
- (instancetype)init
{
    self = [super init];
    if (self) {
        _enable = YES;
        _beautyLevel = 0.5;
        _brightLevel = 0.5;
        
        _pipelineState = [YZMetalDevice.defaultDevice newRenderPipeline:@"YZBrightnessInputVertex" fragment:@"YZBrightnessFragment"];
        
        simd_float8 vertices = [YZMetalOrientation defaultVertices];
        _positionBuffer = [YZMetalDevice.defaultDevice.device newBufferWithBytes:&vertices length:sizeof(simd_float8) options:MTLResourceStorageModeShared];
        
        simd_float8 texture = [YZMetalOrientation defaultTexture];
        _textureBuffer = [YZMetalDevice.defaultDevice.device newBufferWithBytes:&texture length:sizeof(simd_float8) options:MTLResourceStorageModeShared];
    }
    return self;
}


- (void)newTextureAvailable:(id<MTLTexture>)texture index:(NSInteger)index {
    if (_enable && (_beautyLevel > 0 || _brightLevel > 0)) {
        MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:texture.width height:texture.height mipmapped:NO];
        desc.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite | MTLTextureUsageRenderTarget;
        id<MTLTexture> outputTexture = [YZMetalDevice.defaultDevice.device newTextureWithDescriptor:desc];
        [self renderTexture:texture outputTexture:outputTexture];

        [self .render newTextureAvailable:outputTexture];
        //[self.render newTextureAvailable:outputTexture index:index];
    } else {
        [self.render newTextureAvailable:texture];
    }
}

- (void)renderTexture:(id<MTLTexture>)texture outputTexture:(id<MTLTexture>)outputTexture {
    MTLRenderPassDescriptor *desc = [[MTLRenderPassDescriptor alloc] init];
    desc.colorAttachments[0].texture = outputTexture;
    desc.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 1, 1);
    desc.colorAttachments[0].storeAction = MTLStoreActionStore;
    desc.colorAttachments[0].loadAction = MTLLoadActionClear;
    
    id<MTLCommandBuffer> commandBuffer = [YZMetalDevice.defaultDevice.commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:desc];
    if (!encoder) {
        NSLog(@"YZBrightness render endcoder Fail");
    }
    [encoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [encoder setRenderPipelineState:self.pipelineState];
    [encoder setVertexBuffer:_positionBuffer offset:0 atIndex:YZVertexIndexPosition];
    
    [encoder setVertexBuffer:_textureBuffer offset:0 atIndex:YZVertexIndexTextureCoordinate];
    [encoder setFragmentTexture:texture atIndex:YZFragmentTextureIndexNormal];

    simd_float2 uniform = {_brightLevel, _beautyLevel};
    id<MTLBuffer> uniformBuffer = [YZMetalDevice.defaultDevice.device newBufferWithBytes:&uniform length:sizeof(simd_float2) options:MTLResourceCPUCacheModeDefaultCache];
    [encoder setFragmentBuffer:uniformBuffer offset:0 atIndex:YZUniformIndexNormal];
    
    [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    [encoder endEncoding];
    
    [commandBuffer commit];
}
@end
