//
//  Shaders.metal
//  ASCIICamera
//
//  Created by Andrey Karpets on 04.01.2025.
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
#include <simd/simd.h>

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "ShaderTypes.h"

constant half3 kRec709Luma = half3(0.2126, 0.7152, 0.0722);

using namespace metal;

typedef struct
{
    float4 position [[position]];
    float2 texCoord;
} V2F;

vertex V2F vertexShader(constant Vertex* input [[buffer(0)]],
							   uint id [[vertex_id]],
							   constant Uniforms& uniforms [[buffer(1)]])
{
	V2F out;
	Vertex v = input[id];
	float4 position = v.position;
	float4 ndc = uniforms.projectionMatrix * position;
	out.position = ndc;

	out.texCoord = v.textureCoords;
	return out;
}

fragment float4 fragmentShader(V2F in [[stage_in]], texture2d<half> texture [[texture(0)]])
{
    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);

	half4 color = texture.sample(colorSampler, in.texCoord);
	
	return float4(color);
}

kernel void grayscaleCompute(texture2d<half, access::read_write> texture[[texture(0)]], uint2 id [[thread_position_in_grid]]) {
	half4 color = texture.read(id);
	float gray = dot(color.rgb, kRec709Luma);
	half4 result = half4(gray, gray, gray, 1.0);
	
	texture.write(result, id);
}

fragment float4 egdeDetectionFragmentShader(V2F input [[stage_in]],
							  constant FragmentUniforms& uniforms [[buffer(0)]],
							  texture2d<half, access::sample> texture [[texture(0)]]) {
	constexpr sampler s(address::clamp_to_edge, filter::linear);
	half4 tC = texture.sample(s, input.texCoord);
	auto coef = half3(0.2, 0.7, 0.07);
	auto brightness = dot(tC.rgb, coef);
	float dx = dfdx(brightness);
	float dy = dfdy(brightness);
	float grad = length(float2(dx, dy));
	float c = step(0.1, grad);
	float4 result = float4(c, c, c, 1.0);
	return result;
}

fragment float4 asciiFragmentShader(V2F input [[ stage_in ]],
									constant FragmentUniforms& uniforms [[buffer(0)]],
									texture2d<half, access::sample> texture [[ texture(0) ]],
									texture2d<half, access::sample> fontTexture [[ texture(1) ]]) {
	float2 resolution = uniforms.screenSize;
	float2 uv = input.position.xy / resolution;

	float ratio = resolution.x / resolution.y;
	float2 zoom = float2(128);
	zoom.x *= ratio;
	uv *= zoom;

	float2 localUV = fract(uv);
	float2 cid = floor(uv);

	const float charCount = 6.0; // Number of character in font texture

	// Get color of scaled 'pixel'
	constexpr sampler s(address::clamp_to_edge, filter::linear);
	float4 color = float4(texture.sample(s, (cid / zoom)));
	

	// Get luminocity
	const float3 coef = float3(0.212, 0.715, 0.0722);
	float lum = dot(color.rgb, coef);
	
	// Map luminocity to number of character
	int luminocityLevel = int(lum * charCount);

	// Calculate character position inside font texture
	const float charSize = 1.0 / charCount;
	localUV.x = localUV.x * charSize + charSize * luminocityLevel;

	float sample = fontTexture.sample(s, localUV).r;
	float mask = step(0.1, sample);
	
	float4 result = color;
	result = mask * color;
	return result;
}

fragment float4 grayscaleTexture(V2F input [[ stage_in ]],
								 constant FragmentUniforms& uniforms [[buffer(0)]],
								 texture2d<half, access::sample> texture [[ texture(0) ]]) {
	constexpr sampler colorSampler(mip_filter::linear,
								   mag_filter::linear,
								   min_filter::linear);
	
	float4 color = float4(texture.sample(colorSampler, input.texCoord));
	const float3 coef = float3(0.212, 0.715, 0.0722);
	float lum = dot(color.rgb, coef);
	return float4(lum, lum, lum, color.a);
}

fragment float4 pixelateTexture(V2F input [[ stage_in ]],
								constant FragmentUniforms& uniforms [[buffer(0)]],
								constant PixelFragmentUniforms& pixelUniforms [[buffer(1)]],
								texture2d<half, access::sample> texture [[ texture(0) ]]) {
	constexpr sampler colorSampler(mip_filter::linear,
								   mag_filter::linear,
								   min_filter::linear);
	
	float2 resolution = uniforms.screenSize;
	float2 uv = input.position.xy / resolution;
	float2 zoom = float2(pixelUniforms.scale);
	zoom.x *= resolution.x / resolution.y;
	
	float4 color = float4(texture.sample(colorSampler, floor(uv * zoom) / zoom));

	return color;
}
