import Foundation
import SwiftUI
import AVFoundation

// MARK: - Camera View Model
public final class CameraViewModel: ObservableObject {
    @Published public var isStreaming: Bool = false
    @Published public var showingSettings: Bool = false
    @Published public var showingPairing: Bool = false
    @Published public var showingInstructions: Bool = false
    @Published public var showPhotoSnapshotFlash: Bool = false

    public let cameraManager: CameraManager
    public let webRtcClient: WebRTCClient
    public let signalingClient: SignalingClient

    public init(
        cameraManager: CameraManager = .shared,
        webRtcClient: WebRTCClient = .shared,
        signalingClient: SignalingClient = .shared
    ) {
        self.cameraManager = cameraManager
        self.webRtcClient = webRtcClient
        self.signalingClient = signalingClient
    }

    public func onAppear() {
        Task {
            let granted = await cameraManager.requestPermissions()
            if granted {
                cameraManager.startSession()
                signalingClient.connect()
            }
        }
    }

    public func onDisappear() {
        // Stop session if background mode is disabled
        if !UserPreferences.shared.backgroundStreamingEnabled {
            cameraManager.stopSession()
        }
    }

    public func toggleStreaming() {
        if webRtcClient.state == .streaming {
            webRtcClient.stopStreaming()
        } else {
            let defaultSession = "sess_" + UUID().uuidString.prefix(8).lowercased()
            webRtcClient.startStreaming(sessionId: defaultSession)
        }
    }

    public func toggleTorch() {
        cameraManager.toggleTorch()
    }

    public func toggleMute() {
        cameraManager.controls.isMuted.toggle()
    }

    public func switchLens(_ lens: CameraLensType) {
        cameraManager.switchLens(to: lens)
    }

    public func capturePhoto() {
        cameraManager.capturePhoto()
        showPhotoSnapshotFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.showPhotoSnapshotFlash = false
        }
    }
}

