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
/** output CVPixelBufferRef size */
@property (nonatomic, assign) CGSize size;

- (instancetype)initWithSize:(CGSize)size render:(BOOL)render;

- (void)generatePixelBuffer:(id<MTLTexture>)texture;

@end

