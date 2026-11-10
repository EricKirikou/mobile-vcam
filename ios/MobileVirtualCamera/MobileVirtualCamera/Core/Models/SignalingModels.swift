import Foundation

// MARK: - Signaling Models

public struct IceServerConfig: Codable {
    public let urls: [String]
    public let username: String?
    public let credential: String?

    public init(urls: [String], username: String? = nil, credential: String? = nil) {
        self.urls = urls
        self.username = username
        self.credential = credential
    }
}

public struct IceServersResponse: Codable {
    public let success: Bool
    public let iceServers: [IceServerConfig]

    public init(success: Bool, iceServers: [IceServerConfig]) {
        self.success = success
        self.iceServers = iceServers
    }
}

public struct IncomingSessionPayload: Codable {
    public let sessionId: String
    public let fromDeviceId: String
    public let userId: String
    public let videoProfile: VideoProfile?
    public let audioProfile: AudioProfile?
    public let timestamp: Int64
}

public struct VideoProfile: Codable {
    public let resolution: String? // "1080p", "720p", "4k"
    public let fps: Int?
    public let bitrateKbps: Int?
    public let codec: String?

    public init(resolution: String? = "1080p", fps: Int? = 30, bitrateKbps: Int? = 4000, codec: String? = "H264") {
        self.resolution = resolution
        self.fps = fps
        self.bitrateKbps = bitrateKbps
        self.codec = codec
    }
}

public struct AudioProfile: Codable {
    public let enabled: Bool?
    public let sampleRate: Int?
    public let channels: Int?

    public init(enabled: Bool? = true, sampleRate: Int? = 48000, channels: Int? = 1) {
        self.enabled = enabled
        self.sampleRate = sampleRate
        self.channels = channels
    }
}

public struct SessionReadyPayload: Codable {
    public let sessionId: String
    public let connectionType: String // "p2p_direct", "relay_turn"

    public init(sessionId: String, connectionType: String = "p2p_direct") {
        self.sessionId = sessionId
        self.connectionType = connectionType
    }
}

public struct IceCandidatePayload: Codable {
    public let sessionId: String
    public let candidate: String
    public let sdpMid: String?
    public let sdpMLineIndex: Int32?
    public let fromDeviceId: String?

    public init(sessionId: String, candidate: String, sdpMid: String? = nil, sdpMLineIndex: Int32? = nil, fromDeviceId: String? = nil) {
        self.sessionId = sessionId
        self.candidate = candidate
        self.sdpMid = sdpMid
        self.sdpMLineIndex = sdpMLineIndex
        self.fromDeviceId = fromDeviceId
    }
}

public struct SdpPayload: Codable {
    public let sessionId: String
    public let sdp: String
    public let fromDeviceId: String?

    public init(sessionId: String, sdp: String, fromDeviceId: String? = nil) {
        self.sessionId = sessionId
        self.sdp = sdp
        self.fromDeviceId = fromDeviceId
    }
}

public struct MetricsUpdatePayload: Codable {
    public let sessionId: String
    public let latencyMs: Double
    public let fps: Double
    public let bitrateKbps: Double
    public let packetLossPct: Double
    public let batteryLevel: Int

    public init(sessionId: String, latencyMs: Double, fps: Double, bitrateKbps: Double, packetLossPct: Double, batteryLevel: Int) {
        self.sessionId = sessionId
        self.latencyMs = latencyMs
        self.fps = fps
        self.bitrateKbps = bitrateKbps
        self.packetLossPct = packetLossPct
        self.batteryLevel = batteryLevel
    }
}

