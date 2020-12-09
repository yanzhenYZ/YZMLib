//
//  YZYUVToRGBConversion.m
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/9.
//

#import "YZYUVToRGBConversion.h"

matrix_float3x3 kYZColorConversion601DefaultMatrix = (matrix_float3x3){
   (simd_float3){1.164,  1.164, 1.164},
   (simd_float3){0.0, -0.392, 2.017},
   (simd_float3){1.596, -0.813,   0.0},
};

// BT.601 full range
matrix_float3x3 kYZColorConversion601FullRangeMatrix = (matrix_float3x3){
   (simd_float3){1.0,    1.0,    1.0},
   (simd_float3){0.0,    -0.343, 1.765},
   (simd_float3){1.4,    -0.711, 0.0},
};

// BT.709, which is the standard for HDTV.
matrix_float3x3 kYZColorConversion709DefaultMatrix = (matrix_float3x3){
   (simd_float3){1.164,  1.164, 1.164},
   (simd_float3){0.0, -0.213, 2.112},
   (simd_float3){1.793, -0.533,   0.0},
};

@implementation YZYUVToRGBConversion

@end
