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

@implementation YZBrightness
- (instancetype)init
{
    self = [super initWithVertexFunctionName:@"YZBrightnessInputVertex" fragmentFunctionName:@"YZBrightnessFragment"];
    if (self) {
        _enable = YES;
        _beautyLevel = 0.5;
        _brightLevel = 0.5;
        
        /*
        simd_float8 vertices = [YZMetalOrientation defaultVertices];
        _vertexBuffer = [YZMetalDevice.defaultDevice.device newBufferWithBytes:&vertices length:sizeof(simd_float8) options:MTLResourceStorageModeShared];
        
        simd_float8 textureCoordinates = [YZMetalOrientation defaultTextureCoordinates];
        _textureBuffer = [YZMetalDevice.defaultDevice.device newBufferWithBytes:&textureCoordinates length:sizeof(simd_float8) options:MTLResourceStorageModeShared];*/
    }
    return self;
}


- (void)newTextureAvailable:(id<MTLTexture>)texture commandBuffer:(id<MTLCommandBuffer>)commandBuffer {
    if (_enable && (_beautyLevel > 0 || _brightLevel > 0)) {
        MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:texture.width height:texture.height mipmapped:NO];
        desc.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite | MTLTextureUsageRenderTarget;
        id<MTLTexture> outputTexture = [YZMetalDevice.defaultDevice.device newTextureWithDescriptor:desc];
        [self renderTexture:texture outputTexture:outputTexture];
    } else {
        [super newTextureAvailable:texture commandBuffer:commandBuffer];
    }
}

- (void)renderTexture:(id<MTLTexture>)texture outputTexture:(id<MTLTexture>)outputTexture {
    MTLRenderPassDescriptor *desc = [YZMetalDevice newRenderPassDescriptor:outputTexture];
    id<MTLCommandBuffer> commandBuffer = [YZMetalDevice.defaultDevice commandBuffer];
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:desc];
    if (!encoder) {
        NSLog(@"YZBrightness render endcoder Fail");
        return;
    }
    [encoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [encoder setRenderPipelineState:self.pipelineState];
    simd_float8 vertices = [YZMetalOrientation defaultVertices];
    [encoder setVertexBytes:&vertices length:sizeof(simd_float8) atIndex:YZVertexIndexPosition];
    
    simd_float8 textureCoordinates = [YZMetalOrientation defaultTextureCoordinates];
    [encoder setVertexBytes:&textureCoordinates length:sizeof(simd_float8) atIndex:YZVertexIndexTextureCoordinate];
    [encoder setFragmentTexture:texture atIndex:YZFragmentTextureIndexNormal];

    simd_float2 uniform = {_brightLevel, _beautyLevel};
    [encoder setFragmentBytes:&uniform length:sizeof(simd_float2) atIndex:YZUniformIndexNormal];
    
    [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    [encoder endEncoding];
    
    [commandBuffer commit];
    [super newTextureAvailable:outputTexture commandBuffer:commandBuffer];
}
@end
