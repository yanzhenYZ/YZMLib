//
//  YZTexture.h
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/10.
//

#import <UIKit/UIKit.h>
#import <Metal/Metal.h>

@interface YZTexture : NSObject
@property (nonatomic, strong) id<MTLTexture> texture;
@property (nonatomic, assign) UIInterfaceOrientation orientation;
//video and timestamp
- (instancetype)initWithOrientation:(UIInterfaceOrientation)orientation width:(size_t)width height:(size_t)height;

@end


