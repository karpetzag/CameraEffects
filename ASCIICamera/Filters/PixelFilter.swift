//
//  PixelEffect.swift
//  ASCIICamera
//
//  Created by Andrey Karpets on 05.01.2025.
//

import MetalKit

class PixelFilter: IFilter {
			
	var scale: Float = 128
	
	var inputTexture: (any MTLTexture)? {
		didSet {
			self.defaultFilter.inputTexture = self.inputTexture
		}
	}
			
	private let defaultFilter: DefaultSingleInputFragmentFilter
	
	init(device: Device, pixelFormat: MTLPixelFormat) {
		self.defaultFilter = DefaultSingleInputFragmentFilter(
			device: device,
			pixelFormat: pixelFormat,
			functionName: "pixelateTexture"
		)
	}
	
	func encodeCommands(commandBuffer: any MTLCommandBuffer, rendererParameters: RendererParameters) {
		self.defaultFilter.encodeCommands(
			commandBuffer: commandBuffer,
			rendererParameters: rendererParameters) { encoder in
				encoder.setFragmentBytes(&self.scale, length: MemoryLayout<Float>.size, index: 1)
			}
	}
}
