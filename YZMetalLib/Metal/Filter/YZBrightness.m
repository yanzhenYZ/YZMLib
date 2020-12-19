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
@end

@implementation YZBrightness
- (instancetype)init
{
    self = [super init];
    if (self) {
        _pipelineState = [YZMetalDevice.defaultDevice newRenderPipeline:@"YZBrightnessInputVertex" fragment:@"YZBrightnessFragment"];
    }
    return self;
}


- (void)newTextureAvailable:(id<MTLTexture>)texture index:(NSInteger)index {
    if (_brightness > 0) {
        MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:texture.width height:texture.height mipmapped:NO];
        desc.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite | MTLTextureUsageRenderTarget;
        id<MTLTexture> outputTexture = [YZMetalDevice.defaultDevice.device newTextureWithDescriptor:desc];
        [self renderTexture:texture outputTexture:outputTexture];
        
        [self.view newTextureAvailable:outputTexture index:index];
    } else {
        [self.view newTextureAvailable:texture index:index];
    }
}

- (void)renderTexture:(id<MTLTexture>)texture outputTexture:(id<MTLTexture>)outputTexture {
    id<MTLCommandBuffer> commandBuffer = [YZMetalDevice.defaultDevice.commandQueue commandBuffer];
    const float *squareVertices = [YZMetalOrientation defaultVertices];
    id<MTLBuffer> vertexBuffer = [YZMetalDevice.defaultDevice.device newBufferWithBytes:squareVertices length:sizeof(float) * 8 options:MTLResourceCPUCacheModeDefaultCache];
    vertexBuffer.label = @"YZBrightness VertexBuffer";
    
    MTLRenderPassDescriptor *desc = [[MTLRenderPassDescriptor alloc] init];
    desc.colorAttachments[0].texture = outputTexture;
    desc.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 1, 1);
    desc.colorAttachments[0].storeAction = MTLStoreActionStore;
    desc.colorAttachments[0].loadAction = MTLLoadActionClear;
    
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:desc];
    if (!encoder) {
        NSLog(@"YZBrightness render endcoder Fail");
    }
    [encoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [encoder setRenderPipelineState:self.pipelineState];
    [encoder setVertexBuffer:vertexBuffer offset:0 atIndex:YZBrightnessVertexIndexPosition];
    
    
    const float *coordinates = [YZMetalOrientation defaultCoordinates];
    id<MTLBuffer> coordinatesBuffer = [YZMetalDevice.defaultDevice.device newBufferWithBytes:coordinates length:sizeof(float) * 8 options:MTLResourceCPUCacheModeDefaultCache];
    coordinatesBuffer.label = @"YZBrightness coordinatesBuffer";
    [encoder setVertexBuffer:coordinatesBuffer offset:0 atIndex:YZBrightnessVertexIndexTextureCoordinate];
    [encoder setFragmentTexture:texture atIndex:YZBrightnessFragmentIndexTexture];

    //coversion
    id<MTLBuffer> uniformBuffer = [YZMetalDevice.defaultDevice.device newBufferWithBytes:&_brightness length:sizeof(float) options:MTLResourceCPUCacheModeDefaultCache];
    [encoder setFragmentBuffer:uniformBuffer offset:0 atIndex:YZBrightnessUniformIdx];
    
    [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    [encoder endEncoding];
    
    [commandBuffer commit];
}
@end
