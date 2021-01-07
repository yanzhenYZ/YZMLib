//
//  YZRGBRotation.metal
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/14.
//

#include <metal_stdlib>
#import "YZShaderTypes.h"

using namespace metal;


struct YZRGBVertexIO
{
    float4 position [[position]];
    float2 textureCoordinate [[user(texturecoord)]];
};

vertex YZRGBVertexIO YZYRGBVertex(const device packed_float2 *position [[buffer(YZVertexIndexPosition)]],
                                  const device packed_float2 *texturecoord [[buffer(YZVertexIndexTextureCoordinate)]],
                                  uint vertexID [[vertex_id]])
{
    YZRGBVertexIO outputVertices;
    
    outputVertices.position = float4(position[vertexID], 0, 1.0);
    outputVertices.textureCoordinate = texturecoord[vertexID];
    return outputVertices;
}

fragment half4 YZRGBRotationFragment(YZRGBVertexIO fragmentInput [[stage_in]],
                                     texture2d<half> inputTexture [[texture(YZFragmentTextureIndexNormal)]])
{
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    return inputTexture.sample(textureSampler, fragmentInput.textureCoordinate);
}

