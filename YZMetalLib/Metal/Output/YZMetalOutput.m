//
//  YZMetalOutput.m
//  YZMetalLib
//
//  Created by yanzhen on 2021/1/8.
//

#import "YZMetalOutput.h"
#import <Metal/Metal.h>
#import "YZMetalDevice.h"

@interface YZMetalOutput ()

@end

@implementation YZMetalOutput

-(instancetype)initWithVertexFunctionName:(NSString *)vertex fragmentFunctionName:(NSString *)fragment {
    self = [super init];
    if (self) {
        [self generatePipelineVertexFunctionName:vertex fragmentFunctionName:fragment];
    }
    return self;
}

- (void)generatePipelineVertexFunctionName:(NSString *)vertex fragmentFunctionName:(NSString *)fragment {
    _pipelineState = [YZMetalDevice.defaultDevice newRenderPipeline:vertex fragment:fragment];
}
@end
