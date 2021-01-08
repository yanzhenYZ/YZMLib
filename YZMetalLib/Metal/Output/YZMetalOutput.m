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
@property (nonatomic, strong) NSMutableArray<id<YZFilterProtocol>> *filters;
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
    if (vertex.length > 0 && fragment.length > 0) {
        _pipelineState = [YZMetalDevice.defaultDevice newRenderPipeline:vertex fragment:fragment];
    }
}

- (void)addFilter:(id<YZFilterProtocol>)filter {
    if (![self.filters containsObject:filter]) {
        [self.filters addObject:filter];
    }
}

- (void)removeFilter:(id<YZFilterProtocol>)filter {
    [self.filters removeObject:filter];
}

- (void)removeAllFilters {
    [self.filters removeAllObjects];
}

- (NSArray<id<YZFilterProtocol>> *)allFilters {
    return [NSArray arrayWithArray:self.filters];
}
#pragma mark -
- (NSMutableArray<id<YZFilterProtocol>> *)filters {
    if (!_filters) {
        _filters = [NSMutableArray array];
    }
    return _filters;
}
@end
