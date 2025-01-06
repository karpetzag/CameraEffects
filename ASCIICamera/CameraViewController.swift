//
//  CameraViewController.swift
//  ASCIICamera
//
//  Created by Andrey Karpets on 04.01.2025.
//

import UIKit
import MetalKit

enum FilterType {
	case noFilter
	case ascii
	case pixel
	case grayscale
	case edge
}

class CameraViewController: UIViewController {

	private var renderer: Renderer!
	private var mtkView: MTKView!

	private var session: MetalCameraSession?
	
	@IBOutlet private var buttons: [UIButton]!
	
	private var filterType = FilterType.noFilter
	
	private lazy var renderPipelineStateProvider = RenderPipelineStateProvider(device: self.renderer.device, view: self.renderer.view)
	private lazy var resourceManager = ResourceManager(device: self.renderer.device)

	private lazy var grayscaleEffect = GrayscaleEffect(
		view: self.renderer.view,
		renderPipelineStateProvider: self.renderPipelineStateProvider
	)
	
	private lazy var pixelEffect = PixelEffect(
		view: self.renderer.view,
		renderPipelineStateProvider: self.renderPipelineStateProvider
	)
	
	private lazy var asciiEffect = ASCIIEffect(
		view: self.renderer.view,
		renderPipelineStateProvider: self.renderPipelineStateProvider,
		resourceManager: self.resourceManager
	)
	
	private lazy var edgeDetectionEffect = EdgeDetectionEffect(
		view: self.renderer.view,
		renderPipelineStateProvider: self.renderPipelineStateProvider
	)
	
	private lazy var defaultEffect = BaseEffect(
		view: self.renderer.view,
		renderPipelineStateProvider: self.renderPipelineStateProvider
	)
	
	private lazy var testTexture = self.resourceManager.loadTexture(textureName: "parrot", fromAssets: false)
	
	private var currentEffect: BaseEffect?
	
	override func viewDidLoad() {
		super.viewDidLoad()

		guard let mtkView = view as? MTKView else {
			print("View of CameraViewController is not an MTKView")
			return
		}

		guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
			print("Metal is not supported")
			return
		}

		mtkView.device = defaultDevice
		mtkView.backgroundColor = UIColor.black

		renderer = Renderer(view: mtkView, device: defaultDevice)
		mtkView.colorPixelFormat = .bgra8Unorm
		renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)

		mtkView.delegate = renderer
		
		self.session = MetalCameraSession(
			pixelFormat: .rgb,
			captureDevicePosition: .back,
			captureDeviceType: .builtInWideAngleCamera, 
			frameOrientation: .portrait,
			delegate: self
		)
		
		#if targetEnvironment(simulator)
			self.currentEffect?.commonParameters.inputTexture = self.testTexture
			
		#else
			self.session?.start()
		#endif
		
		self.updateEffect()
	}
}

extension CameraViewController: MetalCameraSessionDelegate {
	
	func metalCameraSession(_ session: MetalCameraSession, didReceiveFrameAsTextures textures: [any MTLTexture], withTimestamp: Double) {
		self.currentEffect?.commonParameters.inputTexture = textures.first
	}
	
	func metalCameraSession(_ session: MetalCameraSession, didUpdateState: MetalCameraSessionState, error: MetalCameraSessionError?) {
		print("Session state \(didUpdateState)")
	}
}

extension CameraViewController {
	
	@IBAction func onAsciiFilterButtonTap(button: UIButton) {
		self.handleFilterButtonTap(button: button, filter: .ascii)
	}
	
	@IBAction func onPixelFilterButtonTap(button: UIButton) {
		self.handleFilterButtonTap(button: button, filter: .pixel)
	}
	
	@IBAction func onGrayscaleFilterButtonTap(button: UIButton) {
		self.handleFilterButtonTap(button: button, filter: .grayscale)
	}
	
	@IBAction func onEdgeDetectionFilterButtonTap(button: UIButton) {
		self.handleFilterButtonTap(button: button, filter: .edge)
	}
	
	private func handleFilterButtonTap(button: UIButton, filter: FilterType) {
		button.isSelected.toggle()
		if self.filterType == filter {
			self.filterType = .noFilter
		} else {
			self.filterType = filter
		}
		
		self.updateEffect()
		
		for someButton in self.buttons {
			if someButton !== button {
				someButton.isSelected = false
			}
		}
	}
	
	private func updateEffect() {
		switch self.filterType {
			case .noFilter:
				self.currentEffect = self.defaultEffect
			case .ascii:
				self.currentEffect = self.asciiEffect
			case .pixel:
				self.currentEffect = self.pixelEffect
			case .grayscale:
				self.currentEffect = self.grayscaleEffect
			case .edge:
				self.currentEffect = self.edgeDetectionEffect
		}
		
		self.renderer.effect = self.currentEffect
		
		#if targetEnvironment(simulator)
			self.currentEffect?.commonParameters.inputTexture = self.testTexture
		#endif
	}
}
