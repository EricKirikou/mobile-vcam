import Foundation

// MARK: - Camera Remote Procedure Call (RPC) Models

public enum CameraAction: String, Codable {
    case startCamera = "START_CAMERA"
    case stopCamera = "STOP_CAMERA"
    case takePhoto = "TAKE_PHOTO"
    case changeResolution = "CHANGE_RESOLUTION"
    case switchCamera = "SWITCH_CAMERA"
    case updateControls = "UPDATE_CONTROLS"
    case getMetrics = "GET_METRICS"
}

public struct CameraRpcCommand: Codable {
    public let commandId: String
    public let action: String
    public let payload: [String: AnyCodable]?
    public let timestamp: Int64

    public init(commandId: String, action: String, payload: [String: AnyCodable]? = nil, timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000)) {
        self.commandId = commandId
        self.action = action
        self.payload = payload
        self.timestamp = timestamp
    }
}

public struct CameraRpcResponse: Codable {
    public let commandId: String
    public let success: Bool
    public let error: String?
    public let data: [String: AnyCodable]?

    public init(commandId: String, success: Bool, error: String? = nil, data: [String: AnyCodable]? = nil) {
        self.commandId = commandId
        self.success = success
        self.error = error
        self.data = data
    }
}

// MARK: - AnyCodable Helper for flexible JSON payload in RPC commands
public struct AnyCodable: Codable, Equatable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            self.value = dict.mapValues { $0.value }
        } else {
            self.value = ()
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }

    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        String(describing: lhs.value) == String(describing: rhs.value)
    }
}

