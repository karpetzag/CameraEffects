//
//  Filter.swift
//  ASCIICamera
//
//  Created by Andrey Karpets on 12.01.2025.
//

import MetalKit

struct RendererParameters {
	
	let metalView: MTKView
	let projectionMatrix: float4x4
}

protocol IFilter: AnyObject {
	
	var inputTexture: MTLTexture? { get set }
		
	func encodeCommands(commandBuffer: any MTLCommandBuffer, rendererParameters: RendererParameters)
}

extension IFilter {
	
	func encodeRenderDefaultUniforms(encoder: MTLRenderCommandEncoder, rendererParameters: RendererParameters) {
		let drawableSize = rendererParameters.metalView.drawableSize
		
		let textureWidth = Float(self.inputTexture?.width ?? 0)
		let textureHeight = Float(self.inputTexture?.height ?? 0)
					
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
			projectionMatrix: rendererParameters.projectionMatrix
		)
		
		var fragmentUniforms = FragmentUniforms(
			screenSize: simd_float2(width, height), time: 0
		)
		
		encoder.setVertexBytes(&quad, length: MemoryLayout<Vertex>.stride * quad.count, index: 0)
		encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)

		encoder.setFragmentBytes(&fragmentUniforms, length: MemoryLayout<FragmentUniforms>.stride, index: 0)
	}
	
	func encodeDrawCommandAndEnd(encoder: MTLRenderCommandEncoder) {
		encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
		encoder.endEncoding()
	}
}

class EmptyFilter: IFilter {
	
	var inputTexture: (any MTLTexture)? {
		didSet {
			self.defaultFilter.inputTexture = self.inputTexture
		}
	}
	
	private let defaultFilter: DefaultSingleInputFragmentFilter
	
	init(device: Device, pixelFormat: MTLPixelFormat) {
		self.defaultFilter = DefaultSingleInputFragmentFilter(device: device, pixelFormat: pixelFormat, functionName: "fragmentShader")
	}
	
	func encodeCommands(commandBuffer: any MTLCommandBuffer, rendererParameters: RendererParameters) {
		self.defaultFilter.encodeCommands(commandBuffer: commandBuffer, rendererParameters: rendererParameters)
	}

}
