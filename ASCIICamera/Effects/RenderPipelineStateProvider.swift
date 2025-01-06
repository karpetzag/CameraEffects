//
//  RenderPipelineStateProvider.swift
//  ASCIICamera
//
//  Created by Andrey Karpets on 05.01.2025.
//

import MetalKit

protocol IRenderPipelineStateProvider {
	
	func makePipelineState(
		fragmentFunctionName: String
	) -> MTLRenderPipelineState
}

class RenderPipelineStateProvider: IRenderPipelineStateProvider {
	
	let device: MTLDevice
	let view: MTKView
	
	init(device: MTLDevice, view: MTKView) {
		self.device = device
		self.view = view
	}
	
	func makePipelineState(
		fragmentFunctionName: String
	) -> MTLRenderPipelineState {
		let library = device.makeDefaultLibrary()
		let vertexShaderFunction = library?.makeFunction(name: "vertexShader")
		let fragmentShaderFunction = library?.makeFunction(name: fragmentFunctionName)
		
		let descriptor = MTLRenderPipelineDescriptor()
		descriptor.vertexFunction = vertexShaderFunction
		descriptor.fragmentFunction = fragmentShaderFunction
		descriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
		
		do {
			return try device.makeRenderPipelineState(descriptor: descriptor)
		} catch {
			fatalError("Failed to create state")
		}
	}
}
