//
//  YZBrightness.metal
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/19.
//

#include <metal_stdlib>
#import "YZShaderTypes.h"

using namespace metal;

constant half3x3 saturateMatrix = half3x3(half3(1.1102,-0.0598,-0.061),half3(-0.0774,1.0826,-0.1186),half3(-0.0228,-0.0228,1.1772));
constant half3 W = half3(0.299, 0.587, 0.114);

struct YZBrightnessVertexIO
{
    float4 position [[position]];
    float2 textureCoordinate;
};

typedef struct
{
    float brightLevel;
    float beautyLevel;
} YZBrightnessUniform;


half hardLight(half pass) {
    half highPass = pass;
    for (int i = 0; i < 5; i++) {
        if (pass <= 0.5) {
            highPass = pass * pass * 2.0;
        } else {
            highPass = 1.0 - ((1.0 - pass) * (1.0 - pass) * 2.0);
        }
    }
    return highPass;
}

vertex YZBrightnessVertexIO YZBrightnessInputVertex(const device packed_float2 *position [[buffer(YZBrightnessVertexIndexPosition)]], const device packed_float2 *texturecoord [[buffer(YZBrightnessVertexIndexTextureCoordinate)]], uint vertexID [[vertex_id]])
{
    YZBrightnessVertexIO outputVertices;
    
    outputVertices.position = float4(position[vertexID], 0, 1.0);
    outputVertices.textureCoordinate = texturecoord[vertexID];
    
    return outputVertices;
}

fragment half4 YZBrightnessFragment(YZBrightnessVertexIO fragmentInput [[stage_in]],
                                  texture2d<half> inputTexture [[texture(YZFragmentTextureIndex)]],
                                  constant YZBrightnessUniform& uniform [[ buffer(YZBrightnessUniformIdx) ]])
{
    constexpr sampler quadSampler (mag_filter::linear, min_filter::linear);
    half3 centralColor = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate).rgb;
    half2 blur[24];
    half2 singleStepOffset = half2(0.0018518518, 0.0012722646);
    //GPUImage use
    //half2 singleStepOffset = half2(2.0 / width, 2.0 / height);
    half2 xy = half2(fragmentInput.textureCoordinate.xy);
    
    blur[0] = xy + singleStepOffset * half2(0.0, -10.0);
    blur[1] = xy + singleStepOffset * half2(0.0, 10.0);
    blur[2] = xy + singleStepOffset * half2(-10.0, 0.0);
    blur[3] = xy + singleStepOffset * half2(10.0, 0.0);
    blur[4] = xy + singleStepOffset * half2(5.0, -8.0);
    blur[5] = xy + singleStepOffset * half2(5.0, 8.0);
    blur[6] = xy + singleStepOffset * half2(-5.0, 8.0);
    blur[7] = xy + singleStepOffset * half2(-5.0, -8.0);
    blur[8] = xy + singleStepOffset * half2(8.0, -5.0);
    blur[9] = xy + singleStepOffset * half2(8.0, 5.0);
    blur[10] = xy + singleStepOffset * half2(-8.0, 5.0);
    blur[11] = xy + singleStepOffset * half2(-8.0, -5.0);
    blur[12] = xy + singleStepOffset * half2(0.0, -6.0);
    blur[13] = xy + singleStepOffset * half2(0.0, 6.0);
    blur[14] = xy + singleStepOffset * half2(6.0, 0.0);
    blur[15] = xy + singleStepOffset * half2(-6.0, 0.0);
    blur[16] = xy + singleStepOffset * half2(-4.0, -4.0);
    blur[17] = xy + singleStepOffset * half2(-4.0, 4.0);
    blur[18] = xy + singleStepOffset * half2(4.0, -4.0);
    blur[19] = xy + singleStepOffset * half2(4.0, 4.0);
    blur[20] = xy + singleStepOffset * half2(-2.0, -2.0);
    blur[21] = xy + singleStepOffset * half2(-2.0, 2.0);
    blur[22] = xy + singleStepOffset * half2(2.0, -2.0);
    blur[23] = xy + singleStepOffset * half2(2.0, 2.0);
    
    half g = centralColor.g * 22.0;
    g += inputTexture.sample(quadSampler, float2(blur[0])).g;
    g += inputTexture.sample(quadSampler, float2(blur[1])).g;
    g += inputTexture.sample(quadSampler, float2(blur[2])).g;
    g += inputTexture.sample(quadSampler, float2(blur[3])).g;
    g += inputTexture.sample(quadSampler, float2(blur[4])).g;
    g += inputTexture.sample(quadSampler, float2(blur[5])).g;
    g += inputTexture.sample(quadSampler, float2(blur[6])).g;
    g += inputTexture.sample(quadSampler, float2(blur[7])).g;
    g += inputTexture.sample(quadSampler, float2(blur[8])).g;
    g += inputTexture.sample(quadSampler, float2(blur[9])).g;
    g += inputTexture.sample(quadSampler, float2(blur[10])).g;
    g += inputTexture.sample(quadSampler, float2(blur[11])).g;
    g += inputTexture.sample(quadSampler, float2(blur[12])).g * 2.0;
    g += inputTexture.sample(quadSampler, float2(blur[13])).g * 2.0;
    g += inputTexture.sample(quadSampler, float2(blur[14])).g * 2.0;
    g += inputTexture.sample(quadSampler, float2(blur[15])).g * 2.0;
    g += inputTexture.sample(quadSampler, float2(blur[16])).g * 2.0;
    g += inputTexture.sample(quadSampler, float2(blur[17])).g * 2.0;
    g += inputTexture.sample(quadSampler, float2(blur[18])).g * 2.0;
    g += inputTexture.sample(quadSampler, float2(blur[19])).g * 2.0;
    g += inputTexture.sample(quadSampler, float2(blur[20])).g * 2.0;
    g += inputTexture.sample(quadSampler, float2(blur[21])).g * 2.0;
    g += inputTexture.sample(quadSampler, float2(blur[22])).g * 2.0;
    g += inputTexture.sample(quadSampler, float2(blur[23])).g * 2.0;
    g = g / 62.0;
    
    half highPass = centralColor.g - g + 0.5;
    highPass = hardLight(highPass);
    
    half lumance = dot(centralColor, W);
    
    half beauty = uniform.beautyLevel;
    half tone = 0.5;
    half4 params;
    params.r = 1.0 - 0.6 * beauty;
    params.g = 1.0 - 0.3 * beauty;
    params.b = 0.1 + 0.3 * tone;
    params.a = 0.1 + 0.3 * tone;
    
    half alpha = pow(lumance, params.r);

    half3 smoothColor = centralColor + (centralColor - highPass) * alpha * 0.1;
    smoothColor.r = clamp(pow(smoothColor.r, params.g), half(0.0), half(1.0));
    smoothColor.g = clamp(pow(smoothColor.g, params.g), half(0.0), half(1.0));
    smoothColor.b = clamp(pow(smoothColor.b, params.g), half(0.0), half(1.0));

    half3 lvse = 1.0 - (1.0 - smoothColor) * (1.0 - centralColor);
    half3 bianliang = max(smoothColor, centralColor);
    half3 rouguang = 2.0 * centralColor * smoothColor + centralColor * centralColor - 2.0 * centralColor * centralColor * smoothColor;
    
    half4 color = half4(mix(centralColor, lvse, alpha), 1.0);
    color.rgb = mix(color.rgb, bianliang, alpha);
    color.rgb = mix(color.rgb, rouguang, params.b);
    
    //also can delete this
    half3 satcolor = color.rgb * saturateMatrix;
    color.rgb = mix(color.rgb, satcolor, params.a);
    
    float brightness = uniform.brightLevel * 0.3;//limit 0-0.3
    return half4(color.rgb + brightness, color.a);
}




