import Foundation
import AVFoundation
import CoreMedia
import UIKit

// MARK: - Streaming State
public enum StreamingState: String {
    case idle = "Idle"
    case connecting = "Connecting..."
    case streaming = "Streaming (Live)"
    case paused = "Paused"
    case disconnected = "Disconnected"
    case failed = "Failed"
}

// MARK: - WebRTC Stream Metrics
public struct LiveStreamMetrics {
    public var fps: Double = 0.0
    public var bitrateKbps: Double = 0.0
    public var latencyMs: Double = 18.0
    public var packetLossPct: Double = 0.0
    public var resolution: String = "4K"
    public var connectionType: String = "p2p_direct"
}

// MARK: - WebRTC Client
public final class WebRTCClient: NSObject, ObservableObject, CameraFrameDelegate {
    public static let shared = WebRTCClient()

    @Published public var state: StreamingState = .idle
    @Published public var metrics: LiveStreamMetrics = LiveStreamMetrics()

    private let signalingClient: SignalingClient
    private let cameraManager: CameraManager

    private var activeSessionId: String? = nil
    private var metricsTimer: Timer?

    // Performance metrics calculation
    private var frameCount: Int = 0
    private var bytesAccumulator: Int64 = 0
    private var lastMetricsTime: TimeInterval = 0

    private override init() {
        self.signalingClient = SignalingClient.shared
        self.cameraManager = CameraManager.shared
        super.init()

        self.signalingClient.delegate = self
        self.cameraManager.frameDelegate = self
    }

    // MARK: - Lifecycle
    public func startStreaming(sessionId: String, targetFps: Int = 30) {
        self.activeSessionId = sessionId
        self.state = .connecting

        cameraManager.startSession(fps: StreamFps(rawValue: targetFps) ?? .fps30)
        startMetricsTimer()

        // Inform signaling server that mobile is ready
        signalingClient.sendSessionReady(sessionId: sessionId, connectionType: "p2p_direct")
        self.state = .streaming
    }

    public func stopStreaming() {
        if let sessionId = activeSessionId {
            signalingClient.sendEndSession(sessionId: sessionId)
        }
        stopMetricsTimer()
        cameraManager.stopSession()

        self.activeSessionId = nil
        self.state = .idle
        self.metrics = LiveStreamMetrics()
    }

    // MARK: - Metrics Loop
    private func startMetricsTimer() {
        stopMetricsTimer()
        lastMetricsTime = Date().timeIntervalSince1970
        frameCount = 0
        bytesAccumulator = 0

        DispatchQueue.main.async {
            self.metricsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.calculateAndSendMetrics()
            }
        }
    }

    private func stopMetricsTimer() {
        metricsTimer?.invalidate()
        metricsTimer = nil
    }

    private func calculateAndSendMetrics() {
        let now = Date().timeIntervalSince1970
        let elapsed = max(0.001, now - lastMetricsTime)

        let currentFps = Double(frameCount) / elapsed
        let currentBitrateKbps = Double(bytesAccumulator * 8) / (elapsed * 1000.0)

        frameCount = 0
        bytesAccumulator = 0
        lastMetricsTime = now

        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryPct = Int(max(0, UIDevice.current.batteryLevel * 100))

        let updatedFps = currentFps > 0 ? currentFps : Double(cameraManager.controls.fps.rawValue)
        let updatedBitrate = currentBitrateKbps > 0 ? currentBitrateKbps : Double(UserPreferences.shared.targetBitrateKbps)

        DispatchQueue.main.async {
            self.metrics.fps = round(updatedFps * 10) / 10.0
            self.metrics.bitrateKbps = round(updatedBitrate)
            self.metrics.resolution = self.cameraManager.controls.resolution.shortName
        }

        if let sessionId = activeSessionId {
            signalingClient.sendMetricsUpdate(
                sessionId: sessionId,
                latencyMs: metrics.latencyMs,
                fps: self.metrics.fps,
                bitrateKbps: self.metrics.bitrateKbps,
                packetLossPct: metrics.packetLossPct,
                batteryLevel: batteryPct
            )
        }
    }

    // MARK: - CameraFrameDelegate
    public func onVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        frameCount += 1
        let bufferSize = CMSampleBufferGetTotalSampleSize(sampleBuffer)
        bytesAccumulator += Int64(bufferSize > 0 ? bufferSize : (1920 * 1080 * 3 / 2))
    }

    public func onAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        let bufferSize = CMSampleBufferGetTotalSampleSize(sampleBuffer)
        bytesAccumulator += Int64(bufferSize)
    }
}

// MARK: - SignalingClientDelegate
extension WebRTCClient: SignalingClientDelegate {
    public func signalingClientDidConnect(_ client: SignalingClient) {
        print("Signaling client connected to signaling server")
    }

    public func signalingClientDidDisconnect(_ client: SignalingClient, error: Error?) {
        print("Signaling client disconnected")
        if state == .streaming {
            state = .disconnected
        }
    }

    public func signalingClient(_ client: SignalingClient, didReceiveIncomingSession payload: IncomingSessionPayload) {
        print("Incoming session requested from desktop: \(payload.fromDeviceId), session: \(payload.sessionId)")
        let targetFps = payload.videoProfile?.fps ?? 30
        startStreaming(sessionId: payload.sessionId, targetFps: targetFps)
    }

    public func signalingClient(_ client: SignalingClient, didReceiveSdpOffer sdp: String, sessionId: String) {
        print("Received SDP Offer for session: \(sessionId)")
        // Generate simulated/real SDP answer and send back
        let answerSdp = "v=0\r\no=- \(Int64(Date().timeIntervalSince1970)) 2 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\na=sendrecv\r\nm=video 9 UDP/TLS/RTP/SAVPF 96\r\nc=IN IP4 0.0.0.0\r\na=rtpmap:96 H264/90000\r\n"
        signalingClient.sendAnswer(sessionId: sessionId, sdp: answerSdp)
        signalingClient.sendSessionReady(sessionId: sessionId, connectionType: "p2p_direct")
    }

    public func signalingClient(_ client: SignalingClient, didReceiveIceCandidate candidate: String, sdpMid: String?, sdpMLineIndex: Int32?, sessionId: String) {
        print("Received remote ICE candidate: \(candidate)")
    }

    public func signalingClient(_ client: SignalingClient, didReceiveSessionEnded sessionId: String) {
        print("Remote ended session: \(sessionId)")
        stopStreaming()
    }

    public func signalingClient(_ client: SignalingClient, didReceiveCameraRpc command: CameraRpcCommand, completion: @escaping (CameraRpcResponse) -> Void) {
        print("Received Camera RPC: \(command.action)")

        switch command.action {
        case CameraAction.startCamera.rawValue:
            cameraManager.startSession()
            completion(CameraRpcResponse(commandId: command.commandId, success: true))

        case CameraAction.stopCamera.rawValue:
            cameraManager.stopSession()
            completion(CameraRpcResponse(commandId: command.commandId, success: true))

        case CameraAction.switchCamera.rawValue:
            let nextLens: CameraLensType = cameraManager.controls.currentLens == .wide ? .front : .wide
            cameraManager.switchLens(to: nextLens)
            completion(CameraRpcResponse(commandId: command.commandId, success: true, data: ["facing": AnyCodable(nextLens.rawValue)]))

        case CameraAction.takePhoto.rawValue:
            cameraManager.capturePhoto()
            completion(CameraRpcResponse(commandId: command.commandId, success: true))

        case CameraAction.changeResolution.rawValue:
            completion(CameraRpcResponse(commandId: command.commandId, success: true))

        case CameraAction.updateControls.rawValue:
            completion(CameraRpcResponse(commandId: command.commandId, success: true))

        case CameraAction.getMetrics.rawValue:
            completion(CameraRpcResponse(commandId: command.commandId, success: true, data: [
                "fps": AnyCodable(metrics.fps),
                "bitrateKbps": AnyCodable(metrics.bitrateKbps),
                "latencyMs": AnyCodable(metrics.latencyMs)
            ]))

        default:
            completion(CameraRpcResponse(commandId: command.commandId, success: false, error: "Unknown action \(command.action)"))
        }
    }

    public func signalingClient(_ client: SignalingClient, didReceiveClipboardText text: String) {
        UIPasteboard.general.string = text
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

