//
//  EdgeDetectionEffect.swift
//  ASCIICamera
//
//  Created by Andrey Karpets on 05.01.2025.
//

import MetalKit

class EdgeDetectionEffect: BaseEffect {
	
	override func encodeCommands(commandBuffer: any MTLCommandBuffer, projectionMatrix: float4x4) {
		self.encodeWithDefaultCommands(
			commandBuffer: commandBuffer,
			renderPipelineState: self.state,
			view: self.view,
			parameters: self.commonParameters,
			projectionMatrix: projectionMatrix
		) { encoder in
			encoder.setFragmentTexture(self.commonParameters.inputTexture, index: 0)
		}
	}
	
	override class func fragmentShaderName() -> String {
		"egdeDetectionFragmentShader"
	}
}
