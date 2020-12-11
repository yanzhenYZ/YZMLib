//
//  YZShaderTypes.h
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/10.
//

#ifndef YZShaderTypes_h
#define YZShaderTypes_h


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

#pragma mark - YZMTKView
typedef enum YZMTKViewVertexIndex
{
    YZMTKViewVertexIndexPosition = 0,
    YZMTKViewVertexIndexTextureCoordinate = 1,
} YZMTKViewVertexIndex;

typedef enum YZMTKViewFragmentIndex
{
    YZMTKViewFragmentIndexTexture = 0,
} YZMTKViewFragmentTextureIndex;

#endif /* YZShaderTypes_h */
