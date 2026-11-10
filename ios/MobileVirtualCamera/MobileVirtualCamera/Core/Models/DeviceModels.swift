import Foundation

// MARK: - Device Models

public enum DevicePlatform: String, Codable {
    case ios = "ios"
    case android = "android"
    case windows = "windows"
    case macos = "macos"
    case linux = "linux"
}

public enum DeviceType: String, Codable {
    case mobile = "mobile"
    case desktop = "desktop"
}

public enum DeviceStatus: String, Codable {
    case online = "online"
    case offline = "offline"
    case streaming = "streaming"
    case busy = "busy"
}

public struct CameraLensCapability: Codable, Identifiable, Hashable {
    public var id: String { lens }
    public let lens: String // "back_wide", "back_ultrawide", "back_telephoto", "front"
    public let name: String
    public let maxResolution: String // "3840x2160", "1920x1080", "1280x720"
    public let maxFps: Int
    public let minZoom: Float
    public let maxZoom: Float
    public let hasTorch: Bool
    public let supportsAutoExposure: Bool
    public let supportsAutoFocus: Bool

    public init(lens: String, name: String, maxResolution: String, maxFps: Int, minZoom: Float, maxZoom: Float, hasTorch: Bool, supportsAutoExposure: Bool, supportsAutoFocus: Bool) {
        self.lens = lens
        self.name = name
        self.maxResolution = maxResolution
        self.maxFps = maxFps
        self.minZoom = minZoom
        self.maxZoom = maxZoom
        self.hasTorch = hasTorch
        self.supportsAutoExposure = supportsAutoExposure
        self.supportsAutoFocus = supportsAutoFocus
    }
}

public struct DeviceCapabilities: Codable {
    public let cameras: [CameraLensCapability]
    public let supportedCodecs: [String] // ["H264", "H265", "VP8", "VP9"]
    public let supportedResolutions: [String] // ["4K", "1080p", "720p", "480p"]
    public let supportedFps: [Int] // [24, 30, 60]
    public let supportsMicrophone: Bool
    public let supportsFlashlight: Bool

    public init(cameras: [CameraLensCapability] = [],
                supportedCodecs: [String] = ["H264", "H265"],
                supportedResolutions: [String] = ["4K", "1080p", "720p"],
                supportedFps: [Int] = [30, 60],
                supportsMicrophone: Bool = true,
                supportsFlashlight: Bool = true) {
        self.cameras = cameras
        self.supportedCodecs = supportedCodecs
        self.supportedResolutions = supportedResolutions
        self.supportedFps = supportedFps
        self.supportsMicrophone = supportsMicrophone
        self.supportsFlashlight = supportsFlashlight
    }
}

public struct DeviceTelemetry: Codable {
    public let batteryLevel: Int
    public let isCharging: Bool
    public let thermalState: String // "nominal", "fair", "serious", "critical"
    public let networkType: String // "wifi", "cellular", "none"
    public let freeDiskSpaceMb: Int64

    public init(batteryLevel: Int, isCharging: Bool, thermalState: String, networkType: String, freeDiskSpaceMb: Int64) {
        self.batteryLevel = batteryLevel
        self.isCharging = isCharging
        self.thermalState = thermalState
        self.networkType = networkType
        self.freeDiskSpaceMb = freeDiskSpaceMb
    }
}

public struct DeviceInfo: Codable, Identifiable {
    public var id: String { deviceId }
    public let deviceId: String
    public let name: String
    public let platform: DevicePlatform
    public let model: String
    public let osVersion: String
    public let appVersion: String
    public var status: DeviceStatus
    public let capabilities: DeviceCapabilities
    public var telemetry: DeviceTelemetry?
    public var lastSeenAt: Date?

    public init(deviceId: String, name: String, platform: DevicePlatform = .ios, model: String, osVersion: String, appVersion: String, status: DeviceStatus = .online, capabilities: DeviceCapabilities, telemetry: DeviceTelemetry? = nil, lastSeenAt: Date? = nil) {
        self.deviceId = deviceId
        self.name = name
        self.platform = platform
        self.model = model
        self.osVersion = osVersion
        self.appVersion = appVersion
        self.status = status
        self.capabilities = capabilities
        self.telemetry = telemetry
        self.lastSeenAt = lastSeenAt
    }
}

