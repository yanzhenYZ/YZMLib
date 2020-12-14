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

vertex YZRGBVertexIO YZYRGBVertex(const device packed_float2 *position [[buffer(YZRGBVertexIndexPosition)]],
                                  const device packed_float2 *texturecoord [[buffer(YZRGBVertexIndexRGB)]],
                                  uint vertexID [[vertex_id]])
{
    YZRGBVertexIO outputVertices;
    
    outputVertices.position = float4(position[vertexID], 0, 1.0);
    outputVertices.textureCoordinate = texturecoord[vertexID];
    return outputVertices;
}

fragment half4 YZRGBRotationFragment(YZRGBVertexIO fragmentInput [[stage_in]],
                                     texture2d<half> inputTexture [[texture(YZRGBFragmentIndexTexture)]])
{
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    return inputTexture.sample(textureSampler, fragmentInput.textureCoordinate);
}

