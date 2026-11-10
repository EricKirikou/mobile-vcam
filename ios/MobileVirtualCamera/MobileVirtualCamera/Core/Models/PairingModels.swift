import Foundation

// MARK: - Pairing Models

public struct PairingRequest: Codable {
    public let pairCode: String
    public let deviceId: String
    public let deviceName: String
    public let platform: String

    public init(pairCode: String, deviceId: String, deviceName: String, platform: String = "ios") {
        self.pairCode = pairCode
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.platform = platform
    }
}

public struct PairingResponse: Codable {
    public let success: Bool
    public let message: String?
    public let pairingId: String?
    public let desktopDeviceId: String?
    public let desktopDeviceName: String?
    public let desktopPlatform: String?
    public let status: String?

    public init(success: Bool, message: String? = nil, pairingId: String? = nil, desktopDeviceId: String? = nil, desktopDeviceName: String? = nil, desktopPlatform: String? = nil, status: String? = nil) {
        self.success = success
        self.message = message
        self.pairingId = pairingId
        self.desktopDeviceId = desktopDeviceId
        self.desktopDeviceName = desktopDeviceName
        self.desktopPlatform = desktopPlatform
        self.status = status
    }
}

public struct QRCodePairingPayload: Codable {
    public let type: String // "mvc_pair"
    public let pairCode: String
    public let serverUrl: String
    public let desktopDeviceId: String
    public let desktopName: String
    public let expiresAt: Int64

    public init(type: String = "mvc_pair", pairCode: String, serverUrl: String, desktopDeviceId: String, desktopName: String, expiresAt: Int64) {
        self.type = type
        self.pairCode = pairCode
        self.serverUrl = serverUrl
        self.desktopDeviceId = desktopDeviceId
        self.desktopName = desktopName
        self.expiresAt = expiresAt
    }
}

public struct PairedDevice: Codable, Identifiable {
    public var id: String { pairingId }
    public let pairingId: String
    public let targetDeviceId: String
    public let targetDeviceName: String
    public let targetPlatform: String
    public var isOnline: Bool
    public var lastConnectedAt: Date?

    public init(pairingId: String, targetDeviceId: String, targetDeviceName: String, targetPlatform: String, isOnline: Bool = false, lastConnectedAt: Date? = nil) {
        self.pairingId = pairingId
        self.targetDeviceId = targetDeviceId
        self.targetDeviceName = targetDeviceName
        self.targetPlatform = targetPlatform
        self.isOnline = isOnline
        self.lastConnectedAt = lastConnectedAt
    }
}

