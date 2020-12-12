//
//  YZBGRARotation.metal
//  YZMetalLib
//
//  Created by 闫振 on 2020/12/12.
//

#include <metal_stdlib>
using namespace metal;

#import "YZShaderTypes.h"

using namespace metal;


struct YZRGBVertexIO
{
    float4 position [[position]];
    float2 textureCoordinate [[user(texturecoord)]];
};

vertex YZRGBVertexIO YZYRGBVertex(const device packed_float2 *position [[buffer(YZFullRangeVertexIndexPosition)]],
                                       const device packed_float2 *texturecoord [[buffer(YZFullRangeVertexIndexY)]],
                                       uint vertexID [[vertex_id]])
{
    YZRGBVertexIO outputVertices;
    
    outputVertices.position = float4(position[vertexID], 0, 1.0);
    outputVertices.textureCoordinate = texturecoord[vertexID];
    return outputVertices;
}

fragment half4 YZRGBRotationFragment(YZRGBVertexIO fragmentInput [[stage_in]],
                                     texture2d<half> inputTexture [[texture(YZFullRangeFragmentIndexTextureY)]])
{
//    constexpr sampler quadSampler;
//    half3 yuv;
//    yuv.x = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate).r;
//
//
//    return half4(yuv, 1.0);
    constexpr sampler quadSampler;
    return inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
}

