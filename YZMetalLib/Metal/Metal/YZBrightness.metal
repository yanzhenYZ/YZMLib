//
//  YZBrightness.metal
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/19.
//

#include <metal_stdlib>
#import "YZShaderTypes.h"

using namespace metal;

struct YZBrightnessVertexIO
{
    float4 position [[position]];
    float2 textureCoordinate;
};

typedef struct
{
    float brightness;
} YZBrightnessUniform;

vertex YZBrightnessVertexIO YZBrightnessInputVertex(const device packed_float2 *position [[buffer(YZBrightnessVertexIndexPosition)]], const device packed_float2 *texturecoord [[buffer(YZBrightnessVertexIndexTextureCoordinate)]], uint vertexID [[vertex_id]])
{
    YZBrightnessVertexIO outputVertices;
    
    outputVertices.position = float4(position[vertexID], 0, 1.0);
    outputVertices.textureCoordinate = texturecoord[vertexID];
    
    return outputVertices;
}

fragment half4 YZBrightnessFragment(YZBrightnessVertexIO fragmentInput [[stage_in]],
                                  texture2d<half> inputTexture [[texture(YZBrightnessFragmentIndexTexture)]],
                                  constant YZBrightnessUniform& uniform [[ buffer(YZBrightnessUniformIdx) ]])
{
    constexpr sampler quadSampler;
    
    half4 color = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    
    return half4(color.rgb + uniform.brightness, color.a);
//    return half4(color.rgb + 0.5, color.a);
}
