//
//  MetalCameraSession.swift
//  MetalShaderCamera
//
//  Created by Alex Staravoitau on 24/04/2016.
//  Copyright © 2016 Old Yellow Bricks. All rights reserved.
//

import AVFoundation
import Metal

/**
 *  A protocol for a delegate that may be notified about the capture session events.
 */
public protocol MetalCameraSessionDelegate {
    /**
     Camera session did receive a new frame and converted it to an array of Metal textures. For instance, if the RGB pixel format was selected, the array will have a single texture, whereas if YCbCr was selected, then there will be two textures: the Y texture at index 0, and CbCr texture at index 1 (following the order in a sample buffer).
     
     - parameter session:                   Session that triggered the update
     - parameter didReceiveFrameAsTextures: Frame converted to an array of Metal textures
     - parameter withTimestamp:             Frame timestamp in seconds
     */
    func metalCameraSession(_ session: MetalCameraSession, didReceiveFrameAsTextures: [MTLTexture], withTimestamp: Double)
    
    /**
     Camera session did update capture state
     
     - parameter session:        Session that triggered the update
     - parameter didUpdateState: Capture session state
     - parameter error:          Capture session error or `nil`
     */
    func metalCameraSession(_ session: MetalCameraSession, didUpdateState: MetalCameraSessionState, error: MetalCameraSessionError?)
}

/**
 * A convenient hub for accessing camera data as a stream of Metal textures with corresponding timestamps.
 *
 * Frames are received in the specified orientation set during initialization.
 */
public final class MetalCameraSession: NSObject {
    // MARK: Public interface
    
    /// Frame orientation.
    public let frameOrientation: AVCaptureVideoOrientation?
    
    /// Requested capture device position, i.e. back/front camera
    public let captureDevicePosition: AVCaptureDevice.Position
    
    /// Requested capture device type
    public let captureDeviceType: AVCaptureDevice.DeviceType
    
    /// Delegate that will be notified about state changes and new frames
    public var delegate: MetalCameraSessionDelegate?

    /// Pixel format to be used for grabbing camera data and converting textures
    public let pixelFormat: MetalCameraPixelFormat
    
    /**
     Initializes a new instance with optional values.
     
     - parameter pixelFormat:           Pixel format. Defaults to `.rgb`
     - parameter captureDevicePosition: Camera to be used for capturing. Defaults to `.back`.
     - parameter captureDeviceType:     Device type to be used for capturing. Defaults to `.builtInWideAngleCamera`.
     - parameter frameOrientation:      Desired frame orientation. Defaults to `nil`.
     - parameter delegate:              Delegate. Defaults to `nil`.
     */
    public init(
        pixelFormat: MetalCameraPixelFormat = .rgb,
        captureDevicePosition: AVCaptureDevice.Position = .back,
        captureDeviceType: AVCaptureDevice.DeviceType = .builtInWideAngleCamera,
        frameOrientation: AVCaptureVideoOrientation? = nil,
        delegate: MetalCameraSessionDelegate? = nil
    ) {
        self.pixelFormat = pixelFormat
        self.captureDevicePosition = captureDevicePosition
        self.captureDeviceType = captureDeviceType
        self.frameOrientation = frameOrientation
        self.delegate = delegate
        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(captureSessionRuntimeError), name: NSNotification.Name.AVCaptureSessionRuntimeError, object: nil)
    }
    
    /**
     Starts the capture session. Call this method to start receiving delegate updates with the sample buffers.
     */
    public func start() {
        requestCameraAccess()

        captureSessionQueue.async(execute: {
            do {
                self.captureSession.beginConfiguration()
                try self.initializeInputDevice()
                try self.initializeOutputData()
                self.captureSession.commitConfiguration()
                try self.initializeTextureCache()
                self.captureSession.startRunning()
                self.state = .streaming
            }
            catch let error as MetalCameraSessionError {
                self.handleError(error)
            }
            catch {
                // We only throw `MetalCameraSessionError` errors.
            }
        })
    }

    /**
     Stops the capture session.
     */
    public func stop() {
        captureSessionQueue.async(execute: {
            self.captureSession.stopRunning()
            self.state = .stopped
        })
    }
    
    // MARK: Private properties and methods
    
    /// Current session state.
    fileprivate var state: MetalCameraSessionState = .waiting {
        didSet {
            guard state != .error else { return }
            
            delegate?.metalCameraSession(self, didUpdateState: state, error: nil)
        }
    }

    /// `AVFoundation` capture session object.
    fileprivate var captureSession = AVCaptureSession()

    /// Our internal wrapper for the `AVCaptureDevice`.
    internal var captureDevice = MetalCameraCaptureDevice()

    /// Dispatch queue for capture session events.
    fileprivate var captureSessionQueue = DispatchQueue(label: "MetalCameraSessionQueue", attributes: [])

#if arch(i386) || arch(x86_64)
#else
    /// Texture cache we will use for converting frame images to textures
    internal var textureCache: CVMetalTextureCache?
#endif

    /// `MTLDevice` we need to initialize texture cache
    fileprivate var metalDevice = MTLCreateSystemDefaultDevice()

    /// Current capture input device.
    internal var inputDevice: AVCaptureDeviceInput? {
        didSet {
            if let oldValue = oldValue {
                captureSession.removeInput(oldValue)
            }

            guard let inputDevice = inputDevice else { return }

            captureSession.addInput(inputDevice)
        }
    }
    
    /// Current capture output data stream.
    internal var outputData: AVCaptureVideoDataOutput? {
        didSet {
            if let oldValue = oldValue {
                captureSession.removeOutput(oldValue)
            }

            guard let outputData = outputData else { return }
            
            captureSession.addOutput(outputData)
        }
    }

    /**
     Requests access to camera hardware.
     */
    fileprivate func requestCameraAccess() {
        captureDevice.requestAccess(for: .video) { granted in
            guard granted else {
                self.handleError(.noHardwareAccess)
                return
            }
            
            if self.state != .streaming && self.state != .error {
                self.state = .ready
            }
        }
    }
    
    fileprivate func handleError(_ error: MetalCameraSessionError) {
        if error.isStreamingError() {
            state = .error
        }

        delegate?.metalCameraSession(self, didUpdateState: state, error: error)
    }

    /**
     Initializes the texture cache. We use it to convert frames into textures.
     */
    fileprivate func initializeTextureCache() throws {
#if arch(i386) || arch(x86_64)
        throw MetalCameraSessionError.failedToCreateTextureCache
#else
        guard
            let metalDevice = metalDevice,
			CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, metalDevice, nil, &textureCache) == kCVReturnSuccess
        else {
            throw MetalCameraSessionError.failedToCreateTextureCache
        }
#endif
    }

    /**
     Initializes capture input device with specified media type and device position.
     
     - throws: `MetalCameraSessionError` if we failed to initialize and add input device.
     */
    fileprivate func initializeInputDevice() throws {
        var captureInput: AVCaptureDeviceInput!

        guard let inputDevice = captureDevice.device(for: .video, type: captureDeviceType, position: captureDevicePosition) else {
            throw MetalCameraSessionError.requestedHardwareNotFound
        }

        do {
            captureInput = try AVCaptureDeviceInput(device: inputDevice)
        }
        catch {
            throw MetalCameraSessionError.inputDeviceNotAvailable
        }
        
        guard captureSession.canAddInput(captureInput) else {
            throw MetalCameraSessionError.failedToAddCaptureInputDevice
        }
        
        self.inputDevice = captureInput
    }
    
    /**
     Initializes capture output data stream.
     
     - throws: `MetalCameraSessionError` if we failed to initialize and add output data stream.
     */
    fileprivate func initializeOutputData() throws {
        let outputData = AVCaptureVideoDataOutput()

        outputData.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(pixelFormat.coreVideoType)
        ]
        outputData.alwaysDiscardsLateVideoFrames = true
        outputData.setSampleBufferDelegate(self, queue: captureSessionQueue)
        
        guard captureSession.canAddOutput(outputData) else {
            throw MetalCameraSessionError.failedToAddCaptureOutput
        }
        
        self.outputData = outputData

        // Set the video orientation
        if let frameOrientation = frameOrientation,
           let videoConnection = outputData.connection(with: .video),
           videoConnection.isVideoOrientationSupported
        {
            videoConnection.videoOrientation = frameOrientation
        }
    }
    
    /**
     `AVCaptureSessionRuntimeErrorNotification` callback.
     */
    @objc
    fileprivate func captureSessionRuntimeError() {
        if state == .streaming {
            handleError(.captureSessionRuntimeError)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension MetalCameraSession: AVCaptureVideoDataOutputSampleBufferDelegate {

#if arch(i386) || arch(x86_64)
#else

    /**
     Converts a sample buffer received from camera to a Metal texture
     
     - parameter sampleBuffer: Sample buffer
     - parameter textureCache: Texture cache
     - parameter planeIndex:   Index of the plane for planar buffers. Defaults to 0.
     - parameter pixelFormat:  Metal pixel format. Defaults to `.bgra8Unorm`.
     
     - returns: Metal texture or nil
     */
    private func texture(sampleBuffer: CMSampleBuffer?, textureCache: CVMetalTextureCache?, planeIndex: Int = 0, pixelFormat: MTLPixelFormat = .bgra8Unorm) throws -> MTLTexture {
        guard let sampleBuffer = sampleBuffer else {
            throw MetalCameraSessionError.missingSampleBuffer
        }
        guard let textureCache = textureCache else {
            throw MetalCameraSessionError.failedToCreateTextureCache
        }
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            throw MetalCameraSessionError.failedToGetImageBuffer
        }
        
        let isPlanar = CVPixelBufferIsPlanar(imageBuffer)
        let width = isPlanar ? CVPixelBufferGetWidthOfPlane(imageBuffer, planeIndex) : CVPixelBufferGetWidth(imageBuffer)
        let height = isPlanar ? CVPixelBufferGetHeightOfPlane(imageBuffer, planeIndex) : CVPixelBufferGetHeight(imageBuffer)
        
        var imageTexture: CVMetalTexture?
        
        let result = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, imageBuffer, nil, pixelFormat, width, height, planeIndex, &imageTexture)

        guard
            let unwrappedImageTexture = imageTexture,
            let texture = CVMetalTextureGetTexture(unwrappedImageTexture),
            result == kCVReturnSuccess
        else {
            throw MetalCameraSessionError.failedToCreateTextureFromImage
        }

        return texture
    }
    
    /**
     Strips out the timestamp value out of the sample buffer received from camera.
     
     - parameter sampleBuffer: Sample buffer with the frame data
     
     - returns: Double value for a timestamp in seconds or nil
     */
    private func timestamp(sampleBuffer: CMSampleBuffer?) throws -> Double {
        guard let sampleBuffer = sampleBuffer else {
            throw MetalCameraSessionError.missingSampleBuffer
        }
        
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        guard time != CMTime.invalid else {
            throw MetalCameraSessionError.failedToRetrieveTimestamp
        }
        
        return Double(time.value) / Double(time.timescale)
    }
    
    public func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        do {
            var textures: [MTLTexture]!
            
            switch pixelFormat {
            case .rgb:
                let textureRGB = try texture(sampleBuffer: sampleBuffer, textureCache: textureCache)
                textures = [textureRGB]
            case .yCbCr:
                let textureY = try texture(sampleBuffer: sampleBuffer, textureCache: textureCache, planeIndex: 0, pixelFormat: .r8Unorm)
                let textureCbCr = try texture(sampleBuffer: sampleBuffer, textureCache: textureCache, planeIndex: 1, pixelFormat: .rg8Unorm)
                textures = [textureY, textureCbCr]
            }
            
            let timestamp = try self.timestamp(sampleBuffer: sampleBuffer)
            
            delegate?.metalCameraSession(self, didReceiveFrameAsTextures: textures, withTimestamp: timestamp)
        }
        catch let error as MetalCameraSessionError {
            self.handleError(error)
        }
        catch {
            // We only throw `MetalCameraSessionError` errors.
        }
    }

#endif
    
}
