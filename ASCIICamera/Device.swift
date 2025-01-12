//
//  Device.swift
//  ASCIICamera
//
//  Created by Andrey Karpets on 12.01.2025.
//

import MetalKit

class Device {
	
	let metalDevice: MTLDevice
	
	private lazy var defaultLibrary = self.metalDevice.makeDefaultLibrary()
	
	init(metalDevice: MTLDevice) {
		self.metalDevice = metalDevice
	}
	
	func makePipelineState(
		pixelFormat: MTLPixelFormat,
		fragmentFunctionName: String
	) -> MTLRenderPipelineState {
		let vertexShaderFunction = self.defaultLibrary?.makeFunction(name: "vertexShader")
		let fragmentShaderFunction = self.defaultLibrary?.makeFunction(name: fragmentFunctionName)
		
		let descriptor = MTLRenderPipelineDescriptor()
		descriptor.vertexFunction = vertexShaderFunction
		descriptor.fragmentFunction = fragmentShaderFunction
		descriptor.colorAttachments[0].pixelFormat = pixelFormat
		
		do {
			return try self.metalDevice.makeRenderPipelineState(descriptor: descriptor)
		} catch {
			fatalError("Failed to create state RenderPipelineState")
		}
	}
	
	func makePipelineState(
		computeFunctionName: String
	) -> MTLComputePipelineState {
		guard let function = self.defaultLibrary?.makeFunction(name: computeFunctionName),
			  let state = try? self.metalDevice.makeComputePipelineState(function: function) else {
			fatalError("Failed to create ComputePipelineState")
		}

		return state
	}
}
