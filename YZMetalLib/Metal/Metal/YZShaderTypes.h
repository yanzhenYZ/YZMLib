//
//  YZShaderTypes.h
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/10.
//

#ifndef YZShaderTypes_h
#define YZShaderTypes_h

// Luminance Constants
constant half3 luminanceWeighting = half3(0.2125, 0.7154, 0.0721);  // Values from "Graphics Shaders: Theory and Practice" by Bailey and Cunningham

struct SingleInputVertexIO
{
    float4 position [[position]];
    float2 textureCoordinate [[user(texturecoord)]];
};

struct TwoInputVertexIO
{
    float4 position [[position]];
    float2 textureCoordinate [[user(texturecoord)]];
    float2 textureCoordinate2 [[user(texturecoord2)]];
};


typedef enum YZMTKViewVertexIndex
{
    YZMTKViewVertexIndexPosition = 0,
    YZMTKViewVertexIndexTextureCoordinate = 1,
} YZMTKViewVertexIndex;

typedef enum YZMTKViewFragmentTextureIndex
{
    YZMTKViewFragmentTextureIndexTexture = 0,
} YZMTKViewFragmentTextureIndex;

#endif /* YZShaderTypes_h */
