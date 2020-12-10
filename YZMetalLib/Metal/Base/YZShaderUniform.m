//
//  YZShaderUniform.m
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/10.
//

#import "YZShaderUniform.h"

@interface YZShaderUniform ()
@property (nonatomic, copy) NSArray<MTLStructMember *> *members;
@end

@implementation YZShaderUniform
- (instancetype)initWithMembers:(NSArray<MTLStructMember *> *)members {
    self = [super init];
    if (self) {
        _members = members;
    }
    return self;
}
@end
