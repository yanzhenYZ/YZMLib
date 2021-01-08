//
//  YZNewPixelBuffer.m
//  YZMetalLib
//
//  Created by yanzhen on 2021/1/8.
//

#import "YZNewPixelBuffer.h"

@interface YZNewPixelBuffer ()
@property (nonatomic) CGSize lastTextureSize;
@end

@implementation YZNewPixelBuffer {
    CVPixelBufferRef _pixelBuffer;
}

- (void)dealloc {
    if (_pixelBuffer) {
        CVPixelBufferRelease(_pixelBuffer);
        _pixelBuffer = nil;
    }
}

-(instancetype)initWithSize:(CGSize)size {
    self = [super initWithVertexFunctionName:nil fragmentFunctionName:nil];
    if (self) {
        _size = size;
        _pixelBuffer = nil;
    }
    return self;
}

-(void)newTextureAvailable:(id<MTLTexture>)texture commandBuffer:(id<MTLCommandBuffer>)commandBuffer {
    [commandBuffer waitUntilCompleted];
    [self dealPixelBuffer:texture];
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
    [super newTextureAvailable:texture commandBuffer:commandBuffer];
}

#pragma mark  - private render
- (void)dealPixelBuffer:(id<MTLTexture>)texture {
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
            [self generatePixelBuffer];
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
    [self generatePixelBuffer];
}

- (void)generatePixelBuffer {
    NSDictionary *pixelAttributes = @{(NSString *)kCVPixelBufferIOSurfacePropertiesKey:@{}};
    CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault,
                                            _size.width,
                                            _size.height,
                                            kCVPixelFormatType_32BGRA,
                                            (__bridge CFDictionaryRef)(pixelAttributes),
                                            &_pixelBuffer);
    if (result != kCVReturnSuccess) {
        NSLog(@"YZNewPixelBuffer to create cvpixelbuffer %d", result);
    }
}
@end
