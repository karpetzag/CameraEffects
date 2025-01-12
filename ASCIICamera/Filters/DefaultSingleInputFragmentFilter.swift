//
//  DefaultSingleInputFragmentFilter.swift
//  ASCIICamera
//
//  Created by Andrey Karpets on 12.01.2025.
//

import MetalKit

class DefaultSingleInputFragmentFilter: IFilter {
	
	var inputTexture: (any MTLTexture)?
		
	private let pipelineState: MTLRenderPipelineState
	
	init(device: Device, pixelFormat: MTLPixelFormat, functionName: String) {
		self.pipelineState = device.makePipelineState(
			pixelFormat: pixelFormat,
			fragmentFunctionName: functionName
		)
	}
	
	func encodeCommands(commandBuffer: any MTLCommandBuffer, rendererParameters: RendererParameters) {
		encodeCommands(commandBuffer: commandBuffer, rendererParameters: rendererParameters, additionalEncodeCommandsHandler: nil)
	}
	
	func encodeCommands(
		commandBuffer: any MTLCommandBuffer,
		rendererParameters: RendererParameters,
		additionalEncodeCommandsHandler: ((MTLRenderCommandEncoder) -> Void)?) {
			guard let rpd = rendererParameters.metalView.currentRenderPassDescriptor else {
				return
			}
			
			guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) else {
				return
			}
			
			encoder.setRenderPipelineState(self.pipelineState)
			
			self.encodeRenderDefaultUniforms(encoder: encoder, rendererParameters: rendererParameters)
			
			encoder.setFragmentTexture(self.inputTexture, index: 0)
			
			additionalEncodeCommandsHandler?(encoder)
			
			self.encodeDrawCommandAndEnd(encoder: encoder)
	}
}
