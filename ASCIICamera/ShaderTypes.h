//
//  ShaderTypes.h
//  ASCIICamera
//
//  Created by Andrey Karpets on 04.01.2025.
//

//
//  Header containing types and enum constants shared between Metal shaders and Swift/ObjC source
//
#ifndef ShaderTypes_h
#define ShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
typedef metal::int32_t EnumBackingType;
#else
#import <Foundation/Foundation.h>
typedef NSInteger EnumBackingType;
#endif

#include <simd/simd.h>

typedef struct  {
	simd_float4 position;
	simd_float2 textureCoords;
} Vertex;

typedef struct {
	simd_float2 screenSize;
	matrix_float4x4 projectionMatrix;
} Uniforms;

typedef struct {
	simd_float2 screenSize;
	float time;
} FragmentUniforms;

typedef struct {
	float scale;
} PixelFragmentUniforms;


#endif /* ShaderTypes_h */

