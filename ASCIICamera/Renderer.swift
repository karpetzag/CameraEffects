//
//  Renderer.swift
//  ASCIICamera
//
//  Created by Andrey Karpets on 04.01.2025.
//

import MetalKit

class Renderer: NSObject {
	
	let view: MTKView
	let device: Device

	private lazy var commandQueue: MTLCommandQueue = {
		guard let queue = self.device.metalDevice.makeCommandQueue() else {
			fatalError("Failed to create command queue")
		}

		return queue
	}()
	
	private var projectionMatrix = float4x4.identity

	var filter: (any IFilter)?
	
	init(view: MTKView, device: Device) {
		self.view = view
		self.device = device
		super.init()
		
		self.view.delegate = self
	}
}

private extension Renderer {
	
	func makeProjectionMatrix(width: Float, height: Float) -> float4x4 {
		float4x4.makeOrhtoProjectionMatrix(
			left: 0,
			right: width,
			top: 0,
			bottom: height,
			near: 0,
			far: 1
		)
	}
}

extension Renderer: MTKViewDelegate {
	
	func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
		self.projectionMatrix = makeProjectionMatrix(width: Float(size.width), height: Float(size.height))
	}

	func draw(in view: MTKView) {
		guard let commandBuffer = self.commandQueue.makeCommandBuffer() else {
			return
		}
		
		let rp = RendererParameters(metalView: self.view, projectionMatrix: self.projectionMatrix)
		
		self.filter?.encodeCommands(commandBuffer: commandBuffer, rendererParameters: rp)
				
		commandBuffer.present(view.currentDrawable!)

		commandBuffer.commit()
	}
}
