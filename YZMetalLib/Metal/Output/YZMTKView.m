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

- (void)newTextureAvailable:(id<MTLTexture>)texture index:(NSInteger)index {
    _texture = texture;
    self.drawableSize = CGSizeMake(texture.width, texture.height);
    [self draw];
}

#pragma mark - MTKViewDelegate
- (void)drawInMTKView:(MTKView *)view {
    if (!view.currentDrawable || !_texture) { return; }
    
    id<MTLCommandBuffer> commandBuffer = [YZMetalDevice.defaultDevice.commandQueue commandBuffer];
    id<MTLTexture> outTexture = view.currentDrawable.texture;
    
    const float *outputVertices = [YZMetalOrientation defaultVertices];
    id<MTLBuffer> outputVertexBuffer = [YZMetalDevice.defaultDevice.device newBufferWithBytes:outputVertices length:sizeof(float) * 8 options:MTLResourceCPUCacheModeDefaultCache];
    outputVertexBuffer.label = @"YZMTKView OutputVertexBuffer";
    
    MTLRenderPassDescriptor *desc = [[MTLRenderPassDescriptor alloc] init];
    desc.colorAttachments[0].texture = outTexture;
    desc.colorAttachments[0].clearColor = MTLClearColorMake(1, 0, 0, 1);
    desc.colorAttachments[0].storeAction = MTLStoreActionStore;
    desc.colorAttachments[0].loadAction = MTLLoadActionClear;
    
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:desc];
    if (!encoder) {
        NSLog(@"YZMTKView render endcoder Fail");
    }
    [encoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [encoder setRenderPipelineState:_pipelineState];
    [encoder setVertexBuffer:outputVertexBuffer offset:0 atIndex:YZMTKViewVertexIndexPosition];
    
    const float *vertices = [YZMetalOrientation defaultCoordinates];
    id<MTLBuffer> vertexBuffer = [YZMetalDevice.defaultDevice.device newBufferWithBytes:vertices length:sizeof(float) * 8 options:MTLResourceCPUCacheModeDefaultCache];
    vertexBuffer.label = @"YZMTKView VertexBuffer";
    [encoder setVertexBuffer:vertexBuffer offset:0 atIndex:YZMTKViewVertexIndexTextureCoordinate];
    [encoder setFragmentTexture:_texture atIndex:YZMTKViewFragmentIndexTexture];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    [encoder endEncoding];
    
    [commandBuffer presentDrawable:view.currentDrawable];
    [commandBuffer commit];
#if 0
    [self testPixelBuffer:outTexture];
#else
    [self.pixelBuffer cretePixelBuffer:outTexture];
//    if ([_mtkDelegate respondsToSelector:@selector(outputBuffer:)]) {
//        [_mtkDelegate outputBuffer:[self.pixelBuffer outputPixelBuffer]];
//    }
#endif
    _texture = nil;
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}

- (void)testPixelBuffer:(id<MTLTexture>)texture {
    
    NSUInteger width = texture.width;
    NSUInteger height = texture.height;
    
    NSDictionary *pixelAttributes = @{(NSString *)kCVPixelBufferIOSurfacePropertiesKey:@{}};
    
    CVPixelBufferRef pixelBuffer = NULL;
    CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault,
                                            width,
                                            height,
                                            kCVPixelFormatType_32BGRA,
                                            (__bridge CFDictionaryRef)(pixelAttributes),
                                            &pixelBuffer);
    if (result != kCVReturnSuccess) {
        NSLog(@"Unable to create cvpixelbuffer %d", result);
        return;
    }
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *address = CVPixelBufferGetBaseAddress(pixelBuffer);
    if (address) {
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
        
        MTLRegion region = MTLRegionMake2D(0, 0, width, height);
        [texture getBytes:address bytesPerRow:bytesPerRow fromRegion:region mipmapLevel:0];
//        NSLog(@"%@", pixelBuffer);
    }
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    if ([_mtkDelegate respondsToSelector:@selector(outputBuffer:)]) {
        [_mtkDelegate outputBuffer:pixelBuffer];
    }
    
    CVPixelBufferRelease(pixelBuffer);
}

#pragma mark - private config
- (void)_configSelf {
    self.paused = YES;
    self.delegate = self;
    self.framebufferOnly = NO;
    self.enableSetNeedsDisplay = NO;
    self.device = YZMetalDevice.defaultDevice.device;
    self.contentMode = UIViewContentModeScaleAspectFit;
    _pipelineState = [YZMetalDevice.defaultDevice newRenderPipeline:@"YZMTKViewInputVertex" fragment:@"YZMTKViewFragment"];
}
@end
