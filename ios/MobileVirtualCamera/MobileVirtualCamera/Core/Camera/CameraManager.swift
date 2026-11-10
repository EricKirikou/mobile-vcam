import Foundation
import AVFoundation
import UIKit

// MARK: - Frame Delivery Delegate Protocol
public protocol CameraFrameDelegate: AnyObject {
    func onVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer)
    func onAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer)
}

// MARK: - Camera Manager
public final class CameraManager: NSObject, ObservableObject {
    public static let shared = CameraManager()

    // Published State
    @Published public var isRunning: Bool = false
    @Published public var controls: CameraControlsState = CameraControlsState()
    @Published public var availableLenses: [CameraLensType] = [.wide, .front]
    @Published public var capturedPhoto: UIImage? = nil
    @Published public var authorizationStatus: AVAuthorizationStatus = .notDetermined

    public weak var frameDelegate: CameraFrameDelegate?

    // Internal AVFoundation Components
    public let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.mobilevirtualcamera.sessionQueue", qos: .userInteractive)
    private let videoOutputQueue = DispatchQueue(label: "com.mobilevirtualcamera.videoOutputQueue", qos: .userInteractive)
    private let audioOutputQueue = DispatchQueue(label: "com.mobilevirtualcamera.audioOutputQueue", qos: .userInteractive)

    private var currentVideoDeviceInput: AVCaptureDeviceInput?
    private var currentAudioDeviceInput: AVCaptureDeviceInput?
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let audioDataOutput = AVCaptureAudioDataOutput()
    private let photoOutput = AVCapturePhotoOutput()

    private var activeDevice: AVCaptureDevice?

    private override init() {
        super.init()
        checkPermissions()
        discoverAvailableLenses()
    }

    // MARK: - Permissions
    public func checkPermissions() {
        let videoStatus = AVCaptureDevice.authorizationStatus(for: .video)
        DispatchQueue.main.async {
            self.authorizationStatus = videoStatus
        }
    }

    public func requestPermissions() async -> Bool {
        let videoGranted = await AVCaptureDevice.requestAccess(for: .video)
        let audioGranted = await AVCaptureDevice.requestAccess(for: .audio)
        checkPermissions()
        return videoGranted && audioGranted
    }

    // MARK: - Lens Discovery
    private func discoverAvailableLenses() {
        var lenses: [CameraLensType] = []

        let backDiscovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInTripleCamera,
                .builtInDualWideCamera,
                .builtInDualCamera,
                .builtInWideAngleCamera,
                .builtInUltraWideCamera,
                .builtInTelephotoCamera
            ],
            mediaType: .video,
            position: .back
        )

        let backDeviceTypes = Set(backDiscovery.devices.map { $0.deviceType })

        if backDeviceTypes.contains(.builtInUltraWideCamera) || backDeviceTypes.contains(.builtInTripleCamera) {
            lenses.append(.ultraWide)
        }
        lenses.append(.wide) // Standard wide camera is always present
        if backDeviceTypes.contains(.builtInTelephotoCamera) || backDeviceTypes.contains(.builtInTripleCamera) {
            lenses.append(.telephoto)
        }

        // Front Camera
        let frontDiscovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInTrueDepthCamera, .builtInWideAngleCamera],
            mediaType: .video,
            position: .front
        )
        if !frontDiscovery.devices.isEmpty {
            lenses.append(.front)
        }

        DispatchQueue.main.async {
            self.availableLenses = lenses
        }
    }

    // MARK: - Session Setup
    public func startSession(resolution: StreamResolution = .res4K, fps: StreamFps = .fps60, lens: CameraLensType = .wide) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning { return }

            self.session.beginConfiguration()

            // Set preset
            if self.session.canSetSessionPreset(resolution.preset) {
                self.session.sessionPreset = resolution.preset
            } else {
                self.session.sessionPreset = .high
            }

            // Configure Camera Device
            guard let device = self.getDevice(for: lens) else {
                print("Failed to get capture device for lens: \(lens)")
                self.session.commitConfiguration()
                return
            }
            self.activeDevice = device

            do {
                let videoInput = try AVCaptureDeviceInput(device: device)
                if self.session.canAddInput(videoInput) {
                    self.session.addInput(videoInput)
                    self.currentVideoDeviceInput = videoInput
                }

                // Configure Video Data Output
                self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
                self.videoDataOutput.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
                ]
                self.videoDataOutput.setSampleBufferDelegate(self, queue: self.videoOutputQueue)

                if self.session.canAddOutput(self.videoDataOutput) {
                    self.session.addOutput(self.videoDataOutput)
                }

                // Video connection orientation and stabilization
                if let videoConnection = self.videoDataOutput.connection(with: .video) {
                    if videoConnection.isVideoOrientationSupported {
                        videoConnection.videoOrientation = .portrait
                    }
                    if videoConnection.isVideoMirroringSupported {
                        videoConnection.isVideoMirrored = (lens == .front)
                    }
                    if videoConnection.isVideoStabilizationSupported {
                        videoConnection.preferredVideoStabilizationMode = .auto
                    }
                }

                // Configure Microphone Audio
                if let audioDevice = AVCaptureDevice.default(for: .audio) {
                    let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                    if self.session.canAddInput(audioInput) {
                        self.session.addInput(audioInput)
                        self.currentAudioDeviceInput = audioInput
                    }

                    self.audioDataOutput.setSampleBufferDelegate(self, queue: self.audioOutputQueue)
                    if self.session.canAddOutput(self.audioDataOutput) {
                        self.session.addOutput(self.audioDataOutput)
                    }
                }

                // Configure Photo Output
                if self.session.canAddOutput(self.photoOutput) {
                    self.session.addOutput(self.photoOutput)
                }

                self.session.commitConfiguration()

                // Configure Frame Rate
                self.configureFrameRate(device: device, targetFps: fps.rawValue)

                // Start running
                self.session.startRunning()

                DispatchQueue.main.async {
                    self.isRunning = true
                    self.controls.currentLens = lens
                    self.controls.resolution = resolution
                    self.controls.fps = fps
                    self.controls.hasTorch = device.hasTorch
                    self.controls.minZoomFactor = device.minAvailableVideoZoomFactor
                    self.controls.maxZoomFactor = min(device.maxAvailableVideoZoomFactor, 10.0)
                    self.controls.zoomFactor = device.videoZoomFactor
                }
            } catch {
                self.session.commitConfiguration()
                print("Failed to initialize capture session: \(error.localizedDescription)")
            }
        }
    }

    public func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
                DispatchQueue.main.async {
                    self.isRunning = false
                    self.controls.isTorchOn = false
                }
            }
        }
    }

    // MARK: - Lens Switching
    public func switchLens(to lens: CameraLensType) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard let newDevice = self.getDevice(for: lens) else { return }

            self.session.beginConfiguration()

            if let currentInput = self.currentVideoDeviceInput {
                self.session.removeInput(currentInput)
            }

            do {
                let newInput = try AVCaptureDeviceInput(device: newDevice)
                if self.session.canAddInput(newInput) {
                    self.session.addInput(newInput)
                    self.currentVideoDeviceInput = newInput
                    self.activeDevice = newDevice
                }

                if let videoConnection = self.videoDataOutput.connection(with: .video) {
                    if videoConnection.isVideoOrientationSupported {
                        videoConnection.videoOrientation = .portrait
                    }
                    if videoConnection.isVideoMirroringSupported {
                        videoConnection.isVideoMirrored = (lens == .front)
                    }
                }

                self.session.commitConfiguration()
                self.configureFrameRate(device: newDevice, targetFps: self.controls.fps.rawValue)

                DispatchQueue.main.async {
                    self.controls.currentLens = lens
                    self.controls.hasTorch = newDevice.hasTorch
                    self.controls.isTorchOn = false
                    self.controls.minZoomFactor = newDevice.minAvailableVideoZoomFactor
                    self.controls.maxZoomFactor = min(newDevice.maxAvailableVideoZoomFactor, 10.0)
                    self.controls.zoomFactor = newDevice.videoZoomFactor
                }
            } catch {
                self.session.commitConfiguration()
                print("Failed to switch lens: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Resolution & FPS Change
    public func changeResolution(_ resolution: StreamResolution) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.session.beginConfiguration()
            if self.session.canSetSessionPreset(resolution.preset) {
                self.session.sessionPreset = resolution.preset
            }
            self.session.commitConfiguration()

            DispatchQueue.main.async {
                self.controls.resolution = resolution
            }
        }
    }

    public func changeFps(_ fps: StreamFps) {
        sessionQueue.async { [weak self] in
            guard let self = self, let device = self.activeDevice else { return }
            self.configureFrameRate(device: device, targetFps: fps.rawValue)
            DispatchQueue.main.async {
                self.controls.fps = fps
            }
        }
    }

    private func configureFrameRate(device: AVCaptureDevice, targetFps: Int) {
        do {
            try device.lockForConfiguration()
            for range in device.activeFormat.videoSupportedFrameRateRanges {
                if range.maxFrameRate >= Double(targetFps) && range.minFrameRate <= Double(targetFps) {
                    device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(targetFps))
                    device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(targetFps))
                    break
                }
            }
            device.unlockForConfiguration()
        } catch {
            print("Failed to configure frame rate: \(error.localizedDescription)")
        }
    }

    // MARK: - Zoom Controls
    public func setZoom(factor: CGFloat) {
        sessionQueue.async { [weak self] in
            guard let self = self, let device = self.activeDevice else { return }
            let clamped = max(device.minAvailableVideoZoomFactor, min(factor, min(device.maxAvailableVideoZoomFactor, 10.0)))
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = clamped
                device.unlockForConfiguration()

                DispatchQueue.main.async {
                    self.controls.zoomFactor = clamped
                }
            } catch {
                print("Failed to set zoom: \(error)")
            }
        }
    }

    // MARK: - Torch Control
    public func toggleTorch() {
        sessionQueue.async { [weak self] in
            guard let self = self, let device = self.activeDevice, device.hasTorch else { return }
            do {
                try device.lockForConfiguration()
                let target = !self.controls.isTorchOn
                if target {
                    try device.setTorchModeOn(level: 1.0)
                } else {
                    device.torchMode = .off
                }
                device.unlockForConfiguration()

                DispatchQueue.main.async {
                    self.controls.isTorchOn = target
                }
            } catch {
                print("Failed to toggle torch: \(error)")
            }
        }
    }

    // MARK: - Focus & Exposure
    public func focusAndExpose(at point: CGPoint) {
        sessionQueue.async { [weak self] in
            guard let self = self, let device = self.activeDevice else { return }
            do {
                try device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                    device.focusPointOfInterest = point
                    device.focusMode = .autoFocus
                }
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose) {
                    device.exposurePointOfInterest = point
                    device.exposureMode = .autoExpose
                }
                device.unlockForConfiguration()

                DispatchQueue.main.async {
                    self.controls.focusPoint = point
                }
            } catch {
                print("Failed to focus/expose: \(error)")
            }
        }
    }

    // MARK: - Take Photo Snapshot
    public func capturePhoto() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            let settings = AVCapturePhotoSettings()
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    // MARK: - Helpers
    private func getDevice(for lens: CameraLensType) -> AVCaptureDevice? {
        switch lens {
        case .ultraWide:
            return AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) ??
                   AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        case .wide:
            return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        case .telephoto:
            return AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back) ??
                   AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        case .front:
            return AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front) ??
                   AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate & Audio Delegate
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if output == videoDataOutput {
            frameDelegate?.onVideoSampleBuffer(sampleBuffer)
        } else if output == audioDataOutput {
            if !controls.isMuted {
                frameDelegate?.onAudioSampleBuffer(sampleBuffer)
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraManager: AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            return
        }
        DispatchQueue.main.async {
            self.capturedPhoto = image
        }
    }
}

