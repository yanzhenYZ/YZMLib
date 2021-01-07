//
//  YZPixelBuffer.m
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/15.
//

#import "YZPixelBuffer.h"
#import <Metal/Metal.h>
#import "YZMetalDevice.h"
#import "YZMetalOrientation.h"
#import "YZShaderTypes.h"

@interface YZPixelBuffer ()
@property (nonatomic, assign) BOOL render;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@end

@implementation YZPixelBuffer {
    CVPixelBufferRef _pixelBuffer;
}

- (void)dealloc {
    if (_pixelBuffer) {
        CVPixelBufferRelease(_pixelBuffer);
        _pixelBuffer = nil;
    }
}

- (instancetype)initWithRender:(BOOL)render {
    self = [super init];
    if (self) {
        _pixelBuffer = nil;
        _render = render;
        if (!_render) {
            _pipelineState = [YZMetalDevice.defaultDevice newRenderPipeline:@"YZInputVertex" fragment:@"YZFragment"];
        }
    }
    return self;
}

- (void)cretePixelBuffer:(id<MTLTexture>)texture {
    if (_render) {
        [self _createRenderPixelBuffer:texture];
    } else {
        [self _createPixelBuffer:texture];
    }
}

- (CVPixelBufferRef)outputPixelBuffer {
    return _pixelBuffer;
}
#pragma mark - private not render
- (void)_createPixelBuffer:(id<MTLTexture>)texture {
    NSUInteger width = texture.width;
    NSUInteger height = texture.height;
    
    id<MTLCommandBuffer> commandBuffer = [YZMetalDevice.defaultDevice.commandQueue commandBuffer];
    
    id<MTLTexture> outTexture = [self _createOutputTexture:width height:height];
    simd_float8 outputVertices = [YZMetalOrientation defaultVertices];
    id<MTLBuffer> outputVertexBuffer = [YZMetalDevice.defaultDevice.device newBufferWithBytes:&outputVertices length:sizeof(simd_float8) options:MTLResourceCPUCacheModeDefaultCache];
    
    MTLRenderPassDescriptor *desc = [[MTLRenderPassDescriptor alloc] init];
    desc.colorAttachments[0].texture = outTexture;
    desc.colorAttachments[0].clearColor = MTLClearColorMake(1, 0, 0, 1);
    desc.colorAttachments[0].storeAction = MTLStoreActionStore;
    desc.colorAttachments[0].loadAction = MTLLoadActionClear;
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:desc];
    if (!encoder) {
        NSLog(@"YZPixelBuffer render endcoder Fail");
    }
    [encoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [encoder setRenderPipelineState:_pipelineState];
    [encoder setVertexBuffer:outputVertexBuffer offset:0 atIndex:YZVertexIndexPosition];
    
    simd_float8 vertices = [YZMetalOrientation defaultCoordinates];
    id<MTLBuffer> vertexBuffer = [YZMetalDevice.defaultDevice.device newBufferWithBytes:&vertices length:sizeof(simd_float8) options:MTLResourceCPUCacheModeDefaultCache];
    [encoder setVertexBuffer:vertexBuffer offset:0 atIndex:YZVertexIndexTextureCoordinate];
    [encoder setFragmentTexture:texture atIndex:YZFragmentTextureIndexNormal];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    [encoder endEncoding];
    
    //[commandBuffer presentDrawable:view.currentDrawable];
    
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
    
    [self _createRenderPixelBuffer:outTexture];
    
}

- (id<MTLTexture>)_createOutputTexture:(NSUInteger)width height:(NSUInteger)height {
    MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:width height:height mipmapped:NO];
    desc.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite | MTLTextureUsageRenderTarget;
    id<MTLTexture> outputTexture = [YZMetalDevice.defaultDevice.device newTextureWithDescriptor:desc];
    return outputTexture;
}

#pragma mark - private render
- (void)_createRenderPixelBuffer:(id<MTLTexture>)texture {
    NSUInteger width = texture.width;
    NSUInteger height = texture.height;
    if (!_pixelBuffer) {
        if (![self _createPixelBuffer:width height:height buffer:&_pixelBuffer]) {
            return;
        }
    }
    size_t bufferWidth = CVPixelBufferGetWidth(_pixelBuffer);
    size_t bufferHeight = CVPixelBufferGetHeight(_pixelBuffer);
    if (bufferWidth != width || bufferHeight != height) {
        if (![self _createPixelBuffer:width height:height buffer:&_pixelBuffer]) {
            return;
        }
    }
    
    [self _setPixelBuffer:_pixelBuffer texture:texture];
    
    if ([_delegate respondsToSelector:@selector(outputPixelBuffer:)]) {
        [_delegate outputPixelBuffer:_pixelBuffer];
    }
}

- (void)_setPixelBuffer:(CVPixelBufferRef)buffer texture:(id<MTLTexture>)texture  {
    CVPixelBufferLockBaseAddress(buffer, 0);
    void *address = CVPixelBufferGetBaseAddress(buffer);
    if (address) {
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);
        MTLRegion region = MTLRegionMake2D(0, 0, texture.width, texture.height);
        [texture getBytes:address bytesPerRow:bytesPerRow fromRegion:region mipmapLevel:0];
    }
    CVPixelBufferUnlockBaseAddress(buffer, 0);
}

- (BOOL)_createPixelBuffer:(NSUInteger)width height:(NSUInteger)height buffer:(CVPixelBufferRef *)buffer {
    NSDictionary *pixelAttributes = @{(NSString *)kCVPixelBufferIOSurfacePropertiesKey:@{}};
    CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault,
                                            width,
                                            height,
                                            kCVPixelFormatType_32BGRA,
                                            (__bridge CFDictionaryRef)(pixelAttributes),
                                            buffer);
    if (result != kCVReturnSuccess) {
        NSLog(@"YZPixelBuffer to create cvpixelbuffer %d", result);
        return NO;
    }
    return YES;
}
@end
