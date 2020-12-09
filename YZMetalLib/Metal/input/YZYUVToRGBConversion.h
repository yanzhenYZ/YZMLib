//
//  YZYUVToRGBConversion.h
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/9.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>

extern matrix_float3x3 kYZColorConversion601DefaultMatrix;
extern matrix_float3x3 kYZColorConversion601FullRangeMatrix;
extern matrix_float3x3 kYZColorConversion709DefaultMatrix;

@interface YZYUVToRGBConversion : NSObject

@end

