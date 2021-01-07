//
//  YZVertexFragment.metal
//  YZMetalLib
//
//  Created by 闫振 on 2021/1/7.
//

#include <metal_stdlib>
#import "YZShaderTypes.h"

using namespace metal;

struct YZVertexIO
{
    float4 position [[position]];
    float2 textureCoordinate;
};

vertex YZVertexIO YZInputVertex(const device packed_float2 *position [[buffer(YZVertexIndexPosition)]], const device packed_float2 *texturecoord [[buffer(YZVertexIndexTextureCoordinate)]], uint vertexID [[vertex_id]])
{
    YZVertexIO outputVertices;
    
    outputVertices.position = float4(position[vertexID], 0, 1.0);
    outputVertices.textureCoordinate = texturecoord[vertexID];
    
    return outputVertices;
}

fragment half4 YZFragment(YZVertexIO fragmentInput [[stage_in]], texture2d<half> inputTexture [[texture(YZFragmentTextureIndexNormal)]])
{
    constexpr sampler quadSampler;
    half4 color = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    return color;
}

