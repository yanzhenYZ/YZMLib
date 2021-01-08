//
//  YZMetalOutput.h
//  YZMetalLib
//
//  Created by yanzhen on 2021/1/8.
//

#import "YZFilterProtocol.h"

@interface YZMetalOutput : NSObject
@property (nonatomic, strong, readonly) id<MTLRenderPipelineState> pipelineState;
@property (nonatomic, strong) id<YZFilterProtocol> filter;


- (instancetype)initWithVertexFunctionName:(NSString *)vertex fragmentFunctionName:(NSString *)fragment;

- (void)generatePipelineVertexFunctionName:(NSString *)vertex fragmentFunctionName:(NSString *)fragment;
@end

