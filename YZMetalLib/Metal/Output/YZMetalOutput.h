//
//  YZMetalOutput.h
//  YZMetalLib
//
//  Created by yanzhen on 2021/1/8.
//

#import "YZFilterProtocol.h"

@interface YZMetalOutput : NSObject
@property (nonatomic, strong, readonly) id<MTLRenderPipelineState> pipelineState;

- (instancetype)initWithVertexFunctionName:(NSString *)vertex fragmentFunctionName:(NSString *)fragment;

- (void)generatePipelineVertexFunctionName:(NSString *)vertex fragmentFunctionName:(NSString *)fragment;

- (void)addFilter:(id<YZFilterProtocol>)filter;
- (void)removeFilter:(id<YZFilterProtocol>)filter;
- (NSArray<id<YZFilterProtocol>> *)allFilters;//use in render queue
- (void)removeAllFilters;
@end

