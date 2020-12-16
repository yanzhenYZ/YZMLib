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
        _pixelBuffer = nil;
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
//        [self testPixelBuffer:texture];
    } else {
        
    }
}

- (CVPixelBufferRef)outputPixelBuffer {
    return _pixelBuffer;
}

#pragma mark - private

- (void)testPixelBuffer:(id<MTLTexture>)texture {
    NSUInteger width = texture.width;
    NSUInteger height = texture.height;
    CVPixelBufferRef pixelBuffer = NULL;
    [self _createPixelBuffer:width height:height buffer:&pixelBuffer];
    
    [self _setPixelBuffer:pixelBuffer texture:texture];
    
    if ([_delegate respondsToSelector:@selector(outputPixelBuffer:)]) {
        [_delegate outputPixelBuffer:pixelBuffer];
    }
    CVPixelBufferRelease(pixelBuffer);
}

- (void)_createPixelBuffer:(id<MTLTexture>)texture {
    NSUInteger width = texture.width;
    NSUInteger height = texture.height;
//    [self _createPixelBuffer:width height:height buffer:&_pixelBuffer];
    if (!_pixelBuffer) {
        if (![self _createPixelBuffer:width height:height buffer:&_pixelBuffer]) {
            return;
        }
    }
    
//    size_t bufferWidth = CVPixelBufferGetWidth(_pixelBuffer);
//    size_t bufferHeight = CVPixelBufferGetHeight(_pixelBuffer);
//    if (bufferWidth != width || bufferHeight != height) {
//        if (![self _createPixelBuffer:width height:height buffer:&_pixelBuffer]) {
//            return;
//        }
//    }
    [self _setPixelBuffer:_pixelBuffer texture:texture];
    
    if ([_delegate respondsToSelector:@selector(outputPixelBuffer:)]) {
        [_delegate outputPixelBuffer:_pixelBuffer];
    }
//    CVPixelBufferRelease(_pixelBuffer);
}





- (void)_setPixelBuffer:(CVPixelBufferRef)buffer texture:(id<MTLTexture>)texture  {
    CVPixelBufferLockBaseAddress(buffer, 0);
    void *address = CVPixelBufferGetBaseAddress(buffer);
    if (address) {
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);
        NSLog(@"____%d", bytesPerRow);//打开不闪动
        MTLRegion region = MTLRegionMake2D(0, 0, texture.width, texture.height);
        [texture getBytes:address bytesPerRow:bytesPerRow fromRegion:region mipmapLevel:0];
    }
    if ([_delegate respondsToSelector:@selector(outputPixelBuffer:)]) {
        [_delegate outputPixelBuffer:buffer];
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
