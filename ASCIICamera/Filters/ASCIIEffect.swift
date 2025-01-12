//
//  ASCIIEffect.swift
//  ASCIICamera
//
//  Created by Andrey Karpets on 05.01.2025.
//

import MetalKit

class ASCIIFilter: IFilter {
		
	var inputTexture: (any MTLTexture)? {
		didSet {
			self.defaultFilter.inputTexture = self.inputTexture
		}
	}
	
	private lazy var fontTexture = self.resourceManager.loadTexture(textureName: "chars", fromAssets: false)

	private let resourceManager: ResourceManager
			
	private let defaultFilter: DefaultSingleInputFragmentFilter
	
	init(resourceManager: ResourceManager, device: Device, pixelFormat: MTLPixelFormat) {
		self.resourceManager = resourceManager
		self.defaultFilter = DefaultSingleInputFragmentFilter(
			device: device,
			pixelFormat: pixelFormat,
			functionName: "asciiFragmentShader"
		)
	}
	
	func encodeCommands(commandBuffer: any MTLCommandBuffer, rendererParameters: RendererParameters) {
		self.defaultFilter.encodeCommands(
			commandBuffer: commandBuffer,
			rendererParameters: rendererParameters) { encoder in
				encoder.setFragmentTexture(self.fontTexture, index: 1)
			}
	}
}
