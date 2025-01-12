//
//  GrayscaleComputeEffect.swift
//  ASCIICamera
//
//  Created by Andrey Karpets on 11.01.2025.
//

import MetalKit

class GrayscaleFilter: IFilter {
	
	var inputTexture: (any MTLTexture)?
		
	private let pipelineState: MTLComputePipelineState

	init(device: Device) {
		self.pipelineState = device.makePipelineState(computeFunctionName: "grayscaleCompute")
	}
	
	func encodeCommands(commandBuffer: any MTLCommandBuffer, rendererParameters: RendererParameters) {
		guard let encoder = commandBuffer.makeComputeCommandEncoder() else {
			return
		}

		guard let texture = self.inputTexture else {
			assertionFailure("Input texture is nil")
			encoder.endEncoding()
			return
		}

		encoder.setComputePipelineState(self.pipelineState)
		encoder.setTexture(texture, index: 0)

		let width = self.pipelineState.threadExecutionWidth
		let heigth = self.pipelineState.maxTotalThreadsPerThreadgroup / width
		
		encoder.dispatchThreads(
			MTLSize(width: texture.width, height: texture.height, depth: 1),
			threadsPerThreadgroup: MTLSize(width: width, height: heigth, depth: 1)
		)

		encoder.endEncoding()
	}
}
