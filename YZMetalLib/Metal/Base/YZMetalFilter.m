//
//  YZMetalFilter.m
//  YZMetalLib
//
//  Created by yanzhen on 2021/1/8.
//

#import "YZMetalFilter.h"
#import "YZMetalDevice.h"

@interface YZMetalFilter ()

@end

@implementation YZMetalFilter

-(instancetype)init {
    return [super initWithVertexFunctionName:@"YZInputVertex" fragmentFunctionName:@"YZFragment"];
}


#pragma mark - YZFilterProtocol
-(void)newTextureAvailable:(id<MTLTexture>)texture {
    //[self.filter newTextureAvailable:texture];
}
@end
