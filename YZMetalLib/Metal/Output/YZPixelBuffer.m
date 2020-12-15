//
//  YZPixelBuffer.m
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/15.
//

#import "YZPixelBuffer.h"
#import "YZMetalDevice.h"

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
        _render = render;
        if (!_render) {
            _pipelineState = [YZMetalDevice.defaultDevice newRenderPipeline:@"YZMTKViewInputVertex" fragment:@"YZMTKViewFragment"];
        }
    }
    return self;
}

- (void)cretePixelBuffer:(id<MTLTexture>)texture {
    if (_render) {
        [self _createPixelBuffer:texture];
    } else {
        
    }
}

- (CVPixelBufferRef)outputPixelBuffer {
    return _pixelBuffer;
}

#pragma mark - private
- (void)_createPixelBuffer:(id<MTLTexture>)texture {
    NSUInteger width = texture.width;
    NSUInteger height = texture.height;
    if (!_pixelBuffer) {
        if (![self _createPixelBuffer:width height:height]) {
            return;
        }
    }
    size_t bufferWidth = CVPixelBufferGetWidth(_pixelBuffer);
    size_t bufferHeight = CVPixelBufferGetHeight(_pixelBuffer);
    if (bufferWidth != width || bufferHeight != height) {
        if (![self _createPixelBuffer:width height:height]) {
            return;
        }
    }
    CVPixelBufferLockBaseAddress(_pixelBuffer, 0);
    void *address = CVPixelBufferGetBaseAddress(_pixelBuffer);
    if (address) {
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(_pixelBuffer);
        
        MTLRegion region = MTLRegionMake2D(0, 0, width, height);
        [texture getBytes:address bytesPerRow:bytesPerRow fromRegion:region mipmapLevel:0];
    }
    CVPixelBufferUnlockBaseAddress(_pixelBuffer, 0);
}

- (BOOL)_createPixelBuffer:(NSUInteger)width height:(NSUInteger)height {
    NSDictionary *pixelAttributes = @{(NSString *)kCVPixelBufferIOSurfacePropertiesKey:@{}};
    CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault,
                                            width,
                                            height,
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
