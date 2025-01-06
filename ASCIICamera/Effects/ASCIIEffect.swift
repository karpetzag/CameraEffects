//
//  ASCIIEffect.swift
//  ASCIICamera
//
//  Created by Andrey Karpets on 05.01.2025.
//

import MetalKit

class ASCIIEffect: BaseEffect {
	
	private lazy var fontTexture = self.resourceManager.loadTexture(textureName: "chars", fromAssets: false)
	
	private let resourceManager: ResourceManager
	
	init(
		view: MTKView,
		renderPipelineStateProvider: any IRenderPipelineStateProvider,
		resourceManager: ResourceManager
	) {
		self.resourceManager = resourceManager
		super.init(view: view, renderPipelineStateProvider: renderPipelineStateProvider)
	}
	
	override func encodeCommands(commandBuffer: any MTLCommandBuffer, projectionMatrix: float4x4) {
		self.encodeWithDefaultCommands(
			commandBuffer: commandBuffer,
			renderPipelineState: self.state,
			view: self.view,
			parameters: self.commonParameters,
			projectionMatrix: projectionMatrix
		) { encoder in
			encoder.setFragmentTexture(commonParameters.inputTexture, index: 0)
			encoder.setFragmentTexture(self.fontTexture, index: 1)
		}
	}
	
	override class func fragmentShaderName() -> String {
		"asciiFragmentShader"
	}
}
