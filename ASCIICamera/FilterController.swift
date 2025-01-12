//
//  FilterController.swift
//  ASCIICamera
//
//  Created by Andrey Karpets on 12.01.2025.
//

import MetalKit

class FilterController {
	
	var inputTexture: MTLTexture? {
		didSet {
			self.selectedFilter?.inputTexture = self.inputTexture
		}
	}

	var selectedFilter: IFilter?
	
	private let device: Device
	private let renderer: Renderer
	
	private var colorPixelFormat: MTLPixelFormat {
		self.renderer.view.colorPixelFormat
	}
	
	private let resourceManager: ResourceManager
	
	private lazy var emptyFilter = EmptyFilter(device: self.device, pixelFormat: self.colorPixelFormat)
	
	private lazy var pixelFilter = PixelFilter(device: self.device, pixelFormat: self.colorPixelFormat)
	
	private lazy var edgeFilter = EdgeDetectionFilter(device: self.device, pixelFormat: self.colorPixelFormat)
	
	private lazy var grayscaleFilter = GrayscaleFilter(device: self.device)
	
	private lazy var asciiFilter = ASCIIFilter(
		resourceManager: self.resourceManager,
		device: self.device,
		pixelFormat: self.colorPixelFormat
	)
	
	init(device: Device, renderer: Renderer, resourceManager: ResourceManager) {
		self.device = device
		self.renderer = renderer
		self.resourceManager = resourceManager
	}
	
	func selectFilter(type: FilterType) {
		let filter: IFilter = {
			switch type {
				case .noFilter:
					return self.emptyFilter
				case .ascii:
					return self.asciiFilter
				case .pixel:
					return self.pixelFilter
				case .grayscale:
					return self.grayscaleFilter
				case .edge:
					return self.edgeFilter
			}
		}()
		
		self.selectedFilter = filter
		self.renderer.filter = self.selectedFilter
		self.selectedFilter?.inputTexture = self.inputTexture
	}
}
