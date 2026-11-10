import Foundation

// MARK: - WebRTC Configuration
public struct RTCConfig {
    public static let defaultStunServers: [String] = [
        "stun:stun.l.google.com:19302",
        "stun:stun1.l.google.com:19302",
        "stun:stun2.l.google.com:19302"
    ]

    public var iceServers: [IceServerConfig]
    public var preferredVideoCodec: String // "H264" or "H265"
    public var targetBitrateKbps: Int
    public var maxFps: Int

    public init(
        iceServers: [IceServerConfig] = [IceServerConfig(urls: defaultStunServers)],
        preferredVideoCodec: String = "H264",
        targetBitrateKbps: Int = 25000,
        maxFps: Int = 60
    ) {
        self.iceServers = iceServers
        self.preferredVideoCodec = preferredVideoCodec
        self.targetBitrateKbps = targetBitrateKbps
        self.maxFps = maxFps
    }
}

