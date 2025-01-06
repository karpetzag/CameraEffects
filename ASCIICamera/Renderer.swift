//
//  Renderer.swift
//  ASCIICamera
//
//  Created by Andrey Karpets on 04.01.2025.
//

import MetalKit

class Renderer: NSObject {
	
	let view: MTKView
	let device: MTLDevice

	private lazy var commandQueue: MTLCommandQueue = {
		guard let queue = self.device.makeCommandQueue() else {
			fatalError("Failed to create command queue")
		}

		return queue
	}()
	
	private var projectionMatrix = float4x4.identity
	
	var effect: (any Effect)?
	
	init(view: MTKView, device: MTLDevice) {
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
		
		self.effect?.encodeCommands(commandBuffer: commandBuffer, projectionMatrix: projectionMatrix)
		
		commandBuffer.present(view.currentDrawable!)

		commandBuffer.commit()
	}
}
