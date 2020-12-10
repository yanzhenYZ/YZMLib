//
//  YZTexture.m
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/10.
//

#import "YZTexture.h"
#import "YZMetalRenderingDevice.h"

@interface YZTexture ()
//@property (nonatomic, )
@end

@implementation YZTexture
- (instancetype)initWithOrientation:(UIInterfaceOrientation)orientation width:(size_t)width height:(size_t)height {
    self = [super init];
    if (self) {
        _orientation = orientation;
        //make bgra texture
        MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:width height:height mipmapped:NO];
        desc.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite | MTLTextureUsageRenderTarget;
        
        _texture = [YZMetalRenderingDevice.share.device newTextureWithDescriptor:desc];
        if (!_texture) {
            NSLog(@"YZTexture Error to create MTLTexture");
        }
        //video
    }
    return self;
}

- (instancetype)initWithOrientation:(UIInterfaceOrientation)orientation texture:(id<MTLTexture>)texture {
    self = [super init];
    if (self) {
        _orientation = orientation;
        _texture = texture;
        //image
    }
    return self;
}
@end
