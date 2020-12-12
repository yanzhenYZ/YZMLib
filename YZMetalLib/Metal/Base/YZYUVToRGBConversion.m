//
//  YZYUVToRGBConversion.m
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/12.
//

#import "YZYUVToRGBConversion.h"

float YZColorConversion601Default[] = {
    1.164, 1.164,  1.164, 0.0,
    0.0,   -0.392, 2.017, 0.0,
    1.596, -0.813, 0.0,   0.0,
};

// BT.601 full range (ref: http://www.equasys.de/colorconversion.html)
float YZColorConversion601FullRangeDefault[] = {
    1.0, 1.0,    1.0,   0.0,
    0.0, -0.343, 1.765, 0.0,
    1.4, -0.711, 0.0,   0.0,
};

// BT.709, which is the standard for HDTV.
float YZColorConversion709Default[] = {
    1.164, 1.164,  1.164, 0.0,
    0.0,   -0.213, 2.112, 0.0,
    1.793, -0.533, 0.0,   0.0,
};


float *kYZColorConversion601 = YZColorConversion601Default;
float *kYZColorConversion601FullRange = YZColorConversion601FullRangeDefault;
float *kYZColorConversion709 = YZColorConversion709Default;

@implementation YZYUVToRGBConversion

@end
