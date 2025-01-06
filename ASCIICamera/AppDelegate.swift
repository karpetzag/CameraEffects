//
//  AppDelegate.swift
//  ASCIICamera
//
//  Created by Andrey Karpets on 04.01.2025.
//

import MetalKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
	
	var window: UIWindow?
}

/*
protocol IBaseEffect {
	
	func encodeCommands(buffer: MTLBuffer)
}

protocol Effect: IBaseEffect {
	
	associatedtype Params
	
	var params: Params { get set }
}

class BaseEffect: IBaseEffect {
		
	let device: MTLDevice
	let view: MTKView
	
	private let renderPipelineState: MTLRenderPipelineState

	init(device: MTLDevice, view: MTKView) {
		self.device = device
		self.view = view
		
		self.renderPipelineState = Self.makePipelineState(
			device: device,
			colorPixelFormat: view.colorPixelFormat,
			fragmentFunctionName: Self.fragmentShaderFunctionName()
		)
	}
	
	static func makePipelineState(device: MTLDevice, colorPixelFormat: MTLPixelFormat, fragmentFunctionName: String) -> MTLRenderPipelineState {
		let library = device.makeDefaultLibrary()
		let vertexShaderFunction = library?.makeFunction(name: "vertexShader")
		let fragmentShaderFunction = library?.makeFunction(name: fragmentFunctionName)
		
		let descriptor = MTLRenderPipelineDescriptor()
		descriptor.vertexFunction = vertexShaderFunction
		descriptor.fragmentFunction = fragmentShaderFunction
		descriptor.colorAttachments[0].pixelFormat = colorPixelFormat
		
		do {
			return try device.makeRenderPipelineState(descriptor: descriptor)
		} catch {
			fatalError("Failed to create state")
		}
	}
	
	class func fragmentShaderFunctionName() -> String {
		fatalError("Should be overriden by subclasses")
	}
	
	func encodeCommands(buffer: any MTLBuffer) {
		let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: self.view.currentRenderPassDescriptor!)!
		encoder.setRenderPipelineState(self.renderPipelineState)
		
		
		let textureWidth = Float(commonParameters.inputTexture?.width ?? 0)
		let textureHeight = Float(commonParameters.inputTexture?.height ?? 0)
		
		var scaleX = Float(view.drawableSize.width) / textureWidth
		var scaleY = Float(view.drawableSize.height) / textureHeight
		
		if scaleX < scaleY {
			scaleY = scaleX / scaleY
			scaleX = 1.0
		} else {
			scaleX = scaleY / scaleX
			scaleY = 1.0
		}
		
		let width = Float(view.drawableSize.width) * scaleX
		let height = Float(view.drawableSize.height) * scaleY

		var quad = Quad.quadValuesFromRect(Rect(
			0, 0, width, height
		))
		
		var uniforms = Uniforms(
			screenSize: simd_float2(Float(view.drawableSize.width), Float(view.drawableSize.height)),
			projectionMatrix: commonParameters.projectionMatrix
		)
		
		var fragmentUniforms = FragmentUniforms(
			screenSize: simd_float2(width, height), time: 0
		)
		
		encoder.setVertexBytes(&quad, length: MemoryLayout<Vertex>.stride * quad.count, index: 0)
		encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)

		encoder.setFragmentBytes(&fragmentUniforms, length: MemoryLayout<FragmentUniforms>.stride, index: 0)
	}
	
}

class CommonParameters {
	
	var inputTexture: MTLTexture?
	var projectionMatrix: float4x4 = .identity
}

class PixelEffectParams: CommonParameters {
	
}

class PixelEffect: BaseEffect, Effect {
	
	var params = PixelEffectParams()
	
	func encodeCommands(buffer: any MTLBuffer) {
		self.encodeCommonCommands(buffer: buffer, commonParameters: params)
	}
	
	override class func fragmentShaderFunctionName() -> String {
		"pixelateTexture"
	}
}

extension Effect {
	
	func encodeCommonCommands(
		buffer: any MTLBuffer,
		commonParameters: CommonParameters,
		view: MTKView
	) {
		
		let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: self.view.currentRenderPassDescriptor!)!
		encoder.setRenderPipelineState(self.renderPipelineState)
		
		
		let textureWidth = Float(commonParameters.inputTexture?.width ?? 0)
		let textureHeight = Float(commonParameters.inputTexture?.height ?? 0)
		
		var scaleX = Float(view.drawableSize.width) / textureWidth
		var scaleY = Float(view.drawableSize.height) / textureHeight
		
		if scaleX < scaleY {
			scaleY = scaleX / scaleY
			scaleX = 1.0
		} else {
			scaleX = scaleY / scaleX
			scaleY = 1.0
		}
		
		let width = Float(view.drawableSize.width) * scaleX
		let height = Float(view.drawableSize.height) * scaleY

		var quad = Quad.quadValuesFromRect(Rect(
			0, 0, width, height
		))
		
		var uniforms = Uniforms(
			screenSize: simd_float2(Float(view.drawableSize.width), Float(view.drawableSize.height)),
			projectionMatrix: commonParameters.projectionMatrix
		)
		
		var fragmentUniforms = FragmentUniforms(
			screenSize: simd_float2(width, height), time: 0
		)
		
		encoder.setVertexBytes(&quad, length: MemoryLayout<Vertex>.stride * quad.count, index: 0)
		encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)

		encoder.setFragmentBytes(&fragmentUniforms, length: MemoryLayout<FragmentUniforms>.stride, index: 0)
	}
}
*/
