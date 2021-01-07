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
/**
 1. 不渲染输出size
 2. 按比例输出size
 3. 旋转方向后的size
 */
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

-(instancetype)initWithSize:(CGSize)size render:(BOOL)render {
    self = [super init];
    if (self) {
        _pixelBuffer = nil;
        _render = render;
        _size = size;
        if (!_render) {
            _pipelineState = [YZMetalDevice.defaultDevice newRenderPipeline:@"YZInputVertex" fragment:@"YZFragment"];
        }
    }
    return self;
}

- (void)cretePixelBuffer:(id<MTLTexture>)texture {
    if (_render) {
        [self createRenderPixelBuffer:texture];
    } else {
        [self _createPixelBuffer:texture];
    }
}

- (CVPixelBufferRef)outputPixelBuffer {
    return _pixelBuffer;
}
#pragma mark  - private render
- (void)createRenderPixelBuffer:(id<MTLTexture>)texture {
    [self dealWithSize:texture];
    if (!_pixelBuffer) { return; }
    
    CVPixelBufferLockBaseAddress(_pixelBuffer, 0);
    void *address = CVPixelBufferGetBaseAddress(_pixelBuffer);
    if (address) {
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(_pixelBuffer);
        MTLRegion region = MTLRegionMake2D(0, 0, _size.width, _size.height);
        [texture getBytes:address bytesPerRow:bytesPerRow fromRegion:region mipmapLevel:0];
    }
    CVPixelBufferUnlockBaseAddress(_pixelBuffer, 0);
    
    if ([_delegate respondsToSelector:@selector(outputPixelBuffer:)]) {
        [_delegate outputPixelBuffer:_pixelBuffer];
    }
}

- (void)dealWithSize:(id<MTLTexture>)texture {
    CGFloat width = texture.width;
    CGFloat height = texture.height;
    if (CGSizeEqualToSize(_size, CGSizeMake(width, height))) {
        if (!_pixelBuffer) {
            [self createPixelBuffer];
        }
        return;
    }
    CGFloat bufferRatio = width / height;
    CGFloat outoutRatio = _size.width / _size.height;
    if (bufferRatio > outoutRatio * 1.1 || bufferRatio < outoutRatio * 0.9) {
        CGSize outputSize = _size;
        if (bufferRatio > outoutRatio) {
            CGFloat outputW = width * outoutRatio / bufferRatio;
            outputSize = CGSizeMake(outputW, height);
        } else {
            CGFloat outoutH = height * bufferRatio / outoutRatio;
            outputSize = CGSizeMake(width, outoutH);
        }
        if (CGSizeEqualToSize(_size, outputSize) && _pixelBuffer) {
            return;
        }
    } else {
        _size = CGSizeMake(width, height);
    }
    if (_pixelBuffer) {
        CVPixelBufferRelease(_pixelBuffer);
        _pixelBuffer = nil;
    }
    [self createPixelBuffer];
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
    
    [self createRenderPixelBuffer:outTexture];
}

- (id<MTLTexture>)_createOutputTexture:(NSUInteger)width height:(NSUInteger)height {
    MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:width height:height mipmapped:NO];
    desc.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite | MTLTextureUsageRenderTarget;
    id<MTLTexture> outputTexture = [YZMetalDevice.defaultDevice.device newTextureWithDescriptor:desc];
    return outputTexture;
}


- (BOOL)createPixelBuffer {
    NSDictionary *pixelAttributes = @{(NSString *)kCVPixelBufferIOSurfacePropertiesKey:@{}};
    CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault,
                                            _size.width,
                                            _size.height,
                                            kCVPixelFormatType_32BGRA,
                                            (__bridge CFDictionaryRef)(pixelAttributes),
                                            &_pixelBuffer);
    if (result != kCVReturnSuccess) {
        NSLog(@"YZPixelBuffer to create cvpixelbuffer %d", result);
        return NO;
    }
    return YES;
}
@end
