//
//  GrayscaleEffect.swift
//  ASCIICamera
//
//  Created by Andrey Karpets on 05.01.2025.
//

import MetalKit

class GrayscaleEffect: BaseEffect {
		
	override func encodeCommands(commandBuffer: MTLCommandBuffer, projectionMatrix: float4x4) {
		self.encodeWithDefaultCommands(
			commandBuffer: commandBuffer,
			renderPipelineState: self.state,
			view: self.view,
			parameters: self.commonParameters,
			projectionMatrix: projectionMatrix,
			additionalCommands: { encoder in
				encoder.setFragmentTexture(commonParameters.inputTexture, index: 0)
			})
	}
	
	override class func fragmentShaderName() -> String {
		"grayscaleTexture"
	}
}
