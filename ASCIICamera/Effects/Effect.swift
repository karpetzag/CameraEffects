//
//  Filter.swift
//  ASCIICamera
//
//  Created by Andrey Karpets on 05.01.2025.
//

import MetalKit

protocol Effect {

	func encodeCommands(commandBuffer: MTLCommandBuffer, projectionMatrix: float4x4)
}

class CommonEffectParameters {
	var inputTexture: MTLTexture?
}

class BaseEffect: Effect {
	
	let commonParameters = CommonEffectParameters()
	
	let state: MTLRenderPipelineState
	let view: MTKView
	
	init(view: MTKView, renderPipelineStateProvider: IRenderPipelineStateProvider) {
		self.view = view
		self.state = renderPipelineStateProvider.makePipelineState(fragmentFunctionName: Self.fragmentShaderName())
	}
	
	class func fragmentShaderName() -> String {
		"fragmentShader"
	}

	func encodeCommands(commandBuffer: any MTLCommandBuffer, projectionMatrix: float4x4) {
		self.encodeWithDefaultCommands(
			commandBuffer: commandBuffer,
			renderPipelineState: self.state,
			view: view,
			parameters: self.commonParameters,
			projectionMatrix: projectionMatrix) { encoder in
				encoder.setFragmentTexture(commonParameters.inputTexture, index: 0)
			}
	}
}

extension Effect {
	
	func encodeWithDefaultCommands(
		commandBuffer: MTLCommandBuffer,
		renderPipelineState: MTLRenderPipelineState,
		view: MTKView,
		parameters: CommonEffectParameters,
		projectionMatrix: float4x4,
		additionalCommands: (MTLRenderCommandEncoder) -> Void) {
		let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: view.currentRenderPassDescriptor!)!
		encoder.setRenderPipelineState(renderPipelineState)
		
		let textureWidth = Float(parameters.inputTexture?.width ?? 0)
		let textureHeight = Float(parameters.inputTexture?.height ?? 0)
		
		let drawableSize = view.drawableSize
			
		var scaleX = Float(drawableSize.width) / textureWidth
		var scaleY = Float(drawableSize.height) / textureHeight
		
		if scaleX < scaleY {
			scaleY = scaleX / scaleY
			scaleX = 1.0
		} else {
			scaleX = scaleY / scaleX
			scaleY = 1.0
		}
		
		let width = Float(drawableSize.width) * scaleX
		let height = Float(drawableSize.height) * scaleY

		var quad = Quad.quadValuesFromRect(Rect(
			0, 0, width, height
		))
		
		var uniforms = Uniforms(
			screenSize: simd_float2(Float(drawableSize.width), Float(drawableSize.height)),
			projectionMatrix: projectionMatrix
		)
		
		var fragmentUniforms = FragmentUniforms(
			screenSize: simd_float2(width, height), time: 0
		)
		
		encoder.setVertexBytes(&quad, length: MemoryLayout<Vertex>.stride * quad.count, index: 0)
		encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)

		encoder.setFragmentBytes(&fragmentUniforms, length: MemoryLayout<FragmentUniforms>.stride, index: 0)
			
		additionalCommands(encoder)
		
		encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
		encoder.endEncoding()
	}
}
