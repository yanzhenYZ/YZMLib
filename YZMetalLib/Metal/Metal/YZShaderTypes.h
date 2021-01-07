//
//  YZShaderTypes.h
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/10.
//

#ifndef YZShaderTypes_h
#define YZShaderTypes_h


#pragma mark - YZBrightness
typedef enum YZBrightnessVertexIndex
{
    YZBrightnessVertexIndexPosition = 0,
    YZBrightnessVertexIndexTextureCoordinate = 1,
} YZBrightnessVertexIndex;

typedef enum YZBrightnessUniformIndex
{
    YZBrightnessUniformIdx = 0,
} YZBrightnessUniformIndex;
#pragma mark - YZVideoCamera
typedef enum YZRGBVertexIndex
{
    YZRGBVertexIndexPosition  = 0,
    YZRGBVertexIndexRGB       = 1,
} YZRGBVertexIndex;


typedef enum YZFullRangeVertexIndex
{
    YZFullRangeVertexIndexPosition  = 0,
    YZFullRangeVertexIndexY         = 1,
    YZFullRangeVertexIndexUV        = 2,
} YZFullRangeVertexIndex;


typedef enum YZFullRangeFragmentIndex
{
    YZFullRangeFragmentIndexTextureY  = 0,
    YZFullRangeFragmentIndexTextureUV = 1,
} YZFullRangeFragmentIndex;

typedef enum YZFullRangeUniformIndex
{
    YZFullRangeUniform = 0,
} YZFullRangeUniformIndex;

#pragma mark - YZMTKView
typedef enum YZMTKViewVertexIndex
{
    YZMTKViewVertexIndexPosition = 0,
    YZMTKViewVertexIndexTextureCoordinate = 1,
} YZMTKViewVertexIndex;

#pragma mark - normal

typedef enum YZFragmentTexture
{
    YZFragmentTextureIndex
} YZFragmentTexture;

#endif /* YZShaderTypes_h */
