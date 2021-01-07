//
//  YZShaderTypes.h
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/10.
//

#ifndef YZShaderTypes_h
#define YZShaderTypes_h

#pragma mark - YZVideoCamera
typedef enum YZFullRangeVertexIndex
{
    YZFullRangeVertexIndexPosition  = 0,
    YZFullRangeVertexIndexY         = 1,
    YZFullRangeVertexIndexUV        = 2
} YZFullRangeVertexIndex;

typedef enum YZFullRangeFragmentIndex
{
    YZFullRangeFragmentIndexY  = 0,
    YZFullRangeFragmentIndexUV = 1
} YZFullRangeFragmentIndex;

#pragma mark - normal
typedef enum YZVertexIndex
{
    YZVertexIndexPosition = 0,
    YZVertexIndexTextureCoordinate = 1
} YZVertexIndex;

typedef enum YZFragmentTextureIndex
{
    YZFragmentTextureIndexNormal
} YZFragmentTextureIndex;

typedef enum YZUniformIndex
{
    YZUniformIndexNormal
} YZUniformIndex;

#endif /* YZShaderTypes_h */
