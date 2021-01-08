//
//  YZNewPixelBuffer.h
//  YZMetalLib
//
//  Created by yanzhen on 2021/1/8.
//

#import "YZMetalFilter.h"
#import <CoreVideo/CVPixelBuffer.h>
#import <Metal/Metal.h>

@protocol YZNewPixelBufferDelegate <NSObject>

- (void)outputPixelBuffer:(CVPixelBufferRef)buffer;

@end

@interface YZNewPixelBuffer : YZMetalFilter
@property (nonatomic, weak) id<YZNewPixelBufferDelegate> delegate;
/** output CVPixelBufferRef size */
@property (nonatomic, assign) CGSize size;

- (instancetype)initWithVertexFunctionName:(NSString *)vertex fragmentFunctionName:(NSString *)fragment NS_UNAVAILABLE;
- (instancetype)initWithSize:(CGSize)size;

@end

