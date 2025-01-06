//
//  ResourceManager.swift
//  ASCIICamera
//
//  Created by Andrey Karpets on 04.01.2025.
//

import MetalKit

class ResourceManager {
	
	private let device: MTLDevice
	private var cache = [String: MTLTexture]()
	
	init(device: MTLDevice) {
		self.device = device
	}

	func loadTexture(textureName: String, fromAssets: Bool = false) -> MTLTexture? {
		if let cached = self.cache[textureName] {
			return cached
		}
		let textureLoader = MTKTextureLoader(device: device)

		let textureLoaderOptions = [
			MTKTextureLoader.Option.textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
			MTKTextureLoader.Option.textureStorageMode: NSNumber(value: MTLStorageMode.`private`.rawValue),
			.SRGB: false
		]
		
		var texture: MTLTexture?
		if !fromAssets {
			let pathUrl = Bundle.main.url(forResource: textureName, withExtension: "png")
			texture = try? textureLoader.newTexture(
				URL: pathUrl!,
				options: textureLoaderOptions
			)
		} else {
			texture = try? textureLoader.newTexture(
			 name: textureName,
			 scaleFactor: 1.0,
			 bundle: nil,
			 options: textureLoaderOptions
		 )
		}
		
		if let texture = texture {
			self.cache[textureName] = texture
		}
		return texture
	}
}
