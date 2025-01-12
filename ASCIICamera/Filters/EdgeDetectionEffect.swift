//
//  EdgeDetectionEffect.swift
//  ASCIICamera
//
//  Created by Andrey Karpets on 05.01.2025.
//

import MetalKit

class EdgeDetectionFilter: IFilter {
	
	var inputTexture: (any MTLTexture)? {
		didSet {
			self.defaultFilter.inputTexture = inputTexture
		}
	}
			
	private let defaultFilter: DefaultSingleInputFragmentFilter
	
	init(device: Device, pixelFormat: MTLPixelFormat) {
		self.defaultFilter = DefaultSingleInputFragmentFilter(
			device: device,
			pixelFormat: pixelFormat,
			functionName: "egdeDetectionFragmentShader"
		)
	}
	
	func encodeCommands(commandBuffer: any MTLCommandBuffer, rendererParameters: RendererParameters) {
		self.defaultFilter.encodeCommands(commandBuffer: commandBuffer, rendererParameters: rendererParameters)
	}
}
