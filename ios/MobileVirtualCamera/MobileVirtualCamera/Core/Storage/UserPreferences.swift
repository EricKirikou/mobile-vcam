import Foundation

// MARK: - User Preferences
public final class UserPreferences: ObservableObject {
    public static let shared = UserPreferences()

    private let defaults = UserDefaults.standard

    @Published public var serverBaseUrl: String {
        didSet { defaults.set(serverBaseUrl, forKey: "server_base_url") }
    }

    @Published public var deviceId: String {
        didSet { defaults.set(deviceId, forKey: "device_id") }
    }

    @Published public var deviceName: String {
        didSet { defaults.set(deviceName, forKey: "device_name") }
    }

    @Published public var defaultResolution: String {
        didSet { defaults.set(defaultResolution, forKey: "default_resolution") }
    }

    @Published public var defaultFps: Int {
        didSet { defaults.set(defaultFps, forKey: "default_fps") }
    }

    @Published public var targetBitrateKbps: Int {
        didSet { defaults.set(targetBitrateKbps, forKey: "target_bitrate_kbps") }
    }

    @Published public var isAudioEnabled: Bool {
        didSet { defaults.set(isAudioEnabled, forKey: "is_audio_enabled") }
    }

    @Published public var useH265Codec: Bool {
        didSet { defaults.set(useH265Codec, forKey: "use_h265_codec") }
    }

    @Published public var enableVideoStabilization: Bool {
        didSet { defaults.set(enableVideoStabilization, forKey: "enable_video_stabilization") }
    }

    @Published public var backgroundStreamingEnabled: Bool {
        didSet { defaults.set(backgroundStreamingEnabled, forKey: "background_streaming_enabled") }
    }

    private init() {
        self.serverBaseUrl = defaults.string(forKey: "server_base_url") ?? "http://192.168.1.100:5000"
        
        var savedDeviceId = defaults.string(forKey: "device_id")
        if savedDeviceId == nil {
            savedDeviceId = "ios_" + UUID().uuidString.prefix(12).lowercased()
            defaults.set(savedDeviceId, forKey: "device_id")
        }
        self.deviceId = savedDeviceId!

        self.deviceName = defaults.string(forKey: "device_name") ?? (ProcessInfo.processInfo.hostName)
        self.defaultResolution = defaults.string(forKey: "default_resolution") ?? "4K"
        self.defaultFps = defaults.integer(forKey: "default_fps") != 0 ? defaults.integer(forKey: "default_fps") : 60
        self.targetBitrateKbps = defaults.integer(forKey: "target_bitrate_kbps") != 0 ? defaults.integer(forKey: "target_bitrate_kbps") : 25000
        self.isAudioEnabled = defaults.object(forKey: "is_audio_enabled") != nil ? defaults.bool(forKey: "is_audio_enabled") : true
        self.useH265Codec = defaults.bool(forKey: "use_h265_codec")
        self.enableVideoStabilization = defaults.object(forKey: "enable_video_stabilization") != nil ? defaults.bool(forKey: "enable_video_stabilization") : true
        self.backgroundStreamingEnabled = defaults.object(forKey: "background_streaming_enabled") != nil ? defaults.bool(forKey: "background_streaming_enabled") : true
    }
}

