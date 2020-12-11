//
//  YZPassthrough.metal
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/10.
//

#include <metal_stdlib>
#import "YZShaderTypes.h"

using namespace metal;

struct SingleInputVertexIO
{
    float4 position [[position]];
    float2 textureCoordinate;
};

vertex SingleInputVertexIO oneInputVertex(const device packed_float2 *position [[buffer(YZMTKViewVertexIndexPosition)]], const device packed_float2 *texturecoord [[buffer(YZMTKViewVertexIndexTextureCoordinate)]], uint vertexID [[vertex_id]])
{
    SingleInputVertexIO outputVertices;
    
    outputVertices.position = float4(position[vertexID], 0, 1.0);
    outputVertices.textureCoordinate = texturecoord[vertexID];
    
    return outputVertices;
}

fragment half4 passthroughFragment(SingleInputVertexIO fragmentInput [[stage_in]], texture2d<half> inputTexture [[texture(YZMTKViewFragmentTextureIndexTexture)]])
{
    constexpr sampler quadSampler;
    half4 color = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    
    return color;
}
