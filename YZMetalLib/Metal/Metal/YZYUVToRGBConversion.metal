//
//  YZYUVToRGBConversion.metal
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/10.
//

#include <metal_stdlib>
#import "YZShaderTypes.h"

using namespace metal;


struct TwoInputVertexIO
{
    float4 position [[position]];
    float2 textureCoordinate [[user(texturecoord)]];
    float2 textureCoordinate2 [[user(texturecoord2)]];
};

typedef struct
{
    float3x3 colorConversionMatrix;
} YUVConversionUniform;

vertex TwoInputVertexIO twoInputVertex(const device packed_float2 *position [[buffer(0)]],
                                       const device packed_float2 *texturecoord [[buffer(1)]],
                                       const device packed_float2 *texturecoord2 [[buffer(2)]],
                                       uint vid [[vertex_id]])
{
    TwoInputVertexIO outputVertices;
    
    outputVertices.position = float4(position[vid], 0, 1.0);
    outputVertices.textureCoordinate = texturecoord[vid];
    outputVertices.textureCoordinate2 = texturecoord2[vid];

    return outputVertices;
}

fragment half4 yuvConversionFullRangeFragment(TwoInputVertexIO fragmentInput [[stage_in]],
                                     texture2d<half> inputTexture [[texture(0)]],
                                     texture2d<half> inputTexture2 [[texture(1)]],
                                     constant YUVConversionUniform& uniform [[ buffer(1) ]])
{
    constexpr sampler quadSampler;
    half3 yuv;
    yuv.x = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate).r;
    yuv.yz = inputTexture2.sample(quadSampler, fragmentInput.textureCoordinate).rg - half2(0.5, 0.5);

    half3 rgb = half3x3(uniform.colorConversionMatrix) * yuv;
    
    return half4(rgb, 1.0);
}

fragment half4 yuvConversionVideoRangeFragment(TwoInputVertexIO fragmentInput [[stage_in]],
                                              texture2d<half> inputTexture [[texture(0)]],
                                              texture2d<half> inputTexture2 [[texture(1)]],
                                              constant YUVConversionUniform& uniform [[ buffer(1) ]])
{
    constexpr sampler quadSampler;
    half3 yuv;
    yuv.x = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate).r - (16.0/255.0);
    yuv.yz = inputTexture2.sample(quadSampler, fragmentInput.textureCoordinate).ra - half2(0.5, 0.5);
    
    half3 rgb = half3x3(uniform.colorConversionMatrix) * yuv;
    
    return half4(rgb, 1.0);
}
