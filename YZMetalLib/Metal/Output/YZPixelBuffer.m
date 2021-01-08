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
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property (nonatomic, strong) id<MTLBuffer> textureCoordinateBuffer;
@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;
@property (nonatomic, assign) BOOL render;
@property (nonatomic) CGSize lastTextureSize;
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
            
            simd_float8 outputVertices = [YZMetalOrientation defaultVertices];
            _vertexBuffer = [YZMetalDevice.defaultDevice.device newBufferWithBytes:&outputVertices length:sizeof(simd_float8) options:MTLResourceStorageModeShared];
            
            simd_float8 texture = [YZMetalOrientation defaultTexture];
            _textureCoordinateBuffer = [YZMetalDevice.defaultDevice.device newBufferWithBytes:&texture length:sizeof(simd_float8) options:MTLResourceStorageModeShared];
        }
    }
    return self;
}

- (void)generatePixelBuffer:(id<MTLTexture>)texture {
    if (_render) {
        [self createRenderPixelBuffer:texture];
    } else {
        [self createPixelBuffer:texture];
    }
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
    if (_lastTextureSize.width == height && _lastTextureSize.height == width) {//交换了宽高
        CVPixelBufferRelease(_pixelBuffer);
        _pixelBuffer = nil;
        _size = CGSizeMake(_size.height, _size.width);
    }
    _lastTextureSize = CGSizeMake(width, height);
    if (CGSizeEqualToSize(_size, _lastTextureSize)) {
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
- (void)createPixelBuffer:(id<MTLTexture>)texture {
    NSUInteger width = texture.width;
    NSUInteger height = texture.height;
    
    MTLTextureDescriptor *textureDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:width height:height mipmapped:NO];
    textureDesc.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite | MTLTextureUsageRenderTarget;
    id<MTLTexture> outputTexture = [YZMetalDevice.defaultDevice.device newTextureWithDescriptor:textureDesc];
    
    MTLRenderPassDescriptor *desc = [[MTLRenderPassDescriptor alloc] init];
    desc.colorAttachments[0].texture = outputTexture;
    desc.colorAttachments[0].clearColor = MTLClearColorMake(1, 0, 0, 1);
    desc.colorAttachments[0].storeAction = MTLStoreActionStore;
    desc.colorAttachments[0].loadAction = MTLLoadActionClear;
    
    id<MTLCommandBuffer> commandBuffer = [YZMetalDevice.defaultDevice commandBuffer];
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:desc];
    if (!encoder) {
        NSLog(@"YZPixelBuffer render endcoder Fail");
    }
    [encoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [encoder setRenderPipelineState:_pipelineState];
    [encoder setVertexBuffer:_vertexBuffer offset:0 atIndex:YZVertexIndexPosition];
    
    
    [encoder setVertexBuffer:_textureCoordinateBuffer offset:0 atIndex:YZVertexIndexTextureCoordinate];
    [encoder setFragmentTexture:texture atIndex:YZFragmentTextureIndexNormal];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    [encoder endEncoding];
    
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
    
    [self createRenderPixelBuffer:outputTexture];
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
