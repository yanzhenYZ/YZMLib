//
//  Brightness.metal
//  testMetal
//
//  Created by 闫振 on 2020/12/18.
//

#include <metal_stdlib>
using namespace metal;

#include "OperationShaderTypes.h"

using namespace metal;

typedef struct
{
    float brightness;
} BrightnessUniform;

fragment half4 brightnessFragment(SingleInputVertexIO fragmentInput [[stage_in]],
                                  texture2d<half> inputTexture [[texture(0)]],
                                  constant BrightnessUniform& uniform [[ buffer(1) ]])
{
    constexpr sampler quadSampler;
    half4 color = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    
    return half4(color.rgb + uniform.brightness, color.a);
}
