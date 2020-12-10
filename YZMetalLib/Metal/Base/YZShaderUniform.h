//
//  YZShaderUniform.h
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/10.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>

@interface YZShaderUniform : NSObject
@property (nonatomic, assign) matrix_float3x3 colorConversionMatrix;

-(instancetype)initWithMembers:(NSArray <MTLStructMember *> *)members;
@end


