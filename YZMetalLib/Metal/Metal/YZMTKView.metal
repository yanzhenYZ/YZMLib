//
//  YZMTKView.metal
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/10.
//

#include <metal_stdlib>
#import "YZShaderTypes.h"

using namespace metal;

struct YZMTKViewVertexIO
{
    float4 position [[position]];
    float2 textureCoordinate;
};

vertex YZMTKViewVertexIO YZMTKViewInputVertex(const device packed_float2 *position [[buffer(YZVertexIndexPosition)]], const device packed_float2 *texturecoord [[buffer(YZVertexIndexTextureCoordinate)]], uint vertexID [[vertex_id]])
{
    YZMTKViewVertexIO outputVertices;
    
    outputVertices.position = float4(position[vertexID], 0, 1.0);
    outputVertices.textureCoordinate = texturecoord[vertexID];
    
    return outputVertices;
}

fragment half4 YZMTKViewFragment(YZMTKViewVertexIO fragmentInput [[stage_in]], texture2d<half> inputTexture [[texture(YZFragmentTextureIndex)]])
{
    constexpr sampler quadSampler;
    half4 color = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    return color;
}
