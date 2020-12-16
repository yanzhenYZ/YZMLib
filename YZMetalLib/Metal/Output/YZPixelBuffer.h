//
//  YZPixelBuffer.h
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/15.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CVPixelBuffer.h>
#import <Metal/Metal.h>


@protocol YZPixelBufferDelegate <NSObject>

- (void)outputPixelBuffer:(CVPixelBufferRef)buffer;

@end

@interface YZPixelBuffer : NSObject
@property (nonatomic, weak) id<YZPixelBufferDelegate> delegate;

- (instancetype)initWithRender:(BOOL)render;

- (void)cretePixelBuffer:(id<MTLTexture>)texture;
- (CVPixelBufferRef)outputPixelBuffer;

@end

