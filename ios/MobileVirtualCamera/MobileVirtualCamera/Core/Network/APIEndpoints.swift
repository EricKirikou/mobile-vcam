import Foundation

// MARK: - API Endpoints
public enum APIEndpoint {
    case login
    case register
    case refreshToken
    case getMe
    case registerDevice
    case getDevices
    case updateDeviceCapabilities(String)
    case getIceServers
    case claimPairCode
    case getPairings
    case unpairDevice(String)
    case uploadFile

    public var path: String {
        switch self {
        case .login:
            return "/api/auth/login"
        case .register:
            return "/api/auth/register"
        case .refreshToken:
            return "/api/auth/refresh"
        case .getMe:
            return "/api/auth/me"
        case .registerDevice:
            return "/api/devices/register"
        case .getDevices:
            return "/api/devices"
        case .updateDeviceCapabilities(let deviceId):
            return "/api/devices/\(deviceId)/capabilities"
        case .getIceServers:
            return "/api/ice-servers"
        case .claimPairCode:
            return "/api/pairings/claim"
        case .getPairings:
            return "/api/pairings"
        case .unpairDevice(let pairingId):
            return "/api/pairings/\(pairingId)"
        case .uploadFile:
            return "/api/files/upload"
        }
    }

    public var method: String {
        switch self {
        case .login, .register, .refreshToken, .registerDevice, .claimPairCode, .uploadFile:
            return "POST"
        case .getMe, .getDevices, .getIceServers, .getPairings:
            return "GET"
        case .updateDeviceCapabilities:
            return "PUT"
        case .unpairDevice:
            return "DELETE"
        }
    }
}

