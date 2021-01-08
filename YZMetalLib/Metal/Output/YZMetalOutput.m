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
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@end

@implementation YZMetalOutput

-(instancetype)initWithVertexFunctionName:(NSString *)vertex fragmentFunctionName:(NSString *)fragment {
    self = [super init];
    if (self) {
        _pipelineState = [YZMetalDevice.defaultDevice newRenderPipeline:vertex fragment:fragment];
    }
    return self;
}


@end
