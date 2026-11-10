import Foundation
import AVFoundation

// MARK: - Camera Configuration & Types

public enum CameraLensType: String, CaseIterable, Identifiable {
    case wide = "back_wide"
    case ultraWide = "back_ultrawide"
    case telephoto = "back_telephoto"
    case front = "front"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .wide: return "Wide 1x"
        case .ultraWide: return "Ultra Wide 0.5x"
        case .telephoto: return "Telephoto 3x"
        case .front: return "Front (Selfie)"
        }
    }

    public var iconName: String {
        switch self {
        case .wide: return "camera"
        case .ultraWide: return "camera.macro"
        case .telephoto: return "camera.aperture"
        case .front: return "person.crop.square"
        }
    }

    public var position: AVCaptureDevice.Position {
        switch self {
        case .wide, .ultraWide, .telephoto:
            return .back
        case .front:
            return .front
        }
    }
}

public enum StreamResolution: String, CaseIterable, Identifiable {
    case res4K = "4K (3840x2160)"
    case res1080p = "1080p (1920x1080)"
    case res720p = "720p (1280x720)"
    case res480p = "480p (854x480)"

    public var id: String { rawValue }

    public var shortName: String {
        switch self {
        case .res4K: return "4K"
        case .res1080p: return "1080p"
        case .res720p: return "720p"
        case .res480p: return "480p"
        }
    }

    public var width: Int32 {
        switch self {
        case .res4K: return 3840
        case .res1080p: return 1920
        case .res720p: return 1280
        case .res480p: return 854
        }
    }

    public var height: Int32 {
        switch self {
        case .res4K: return 2160
        case .res1080p: return 1080
        case .res720p: return 720
        case .res480p: return 480
        }
    }

    public var preset: AVCaptureSession.Preset {
        switch self {
        case .res4K: return .hd4K3840x2160
        case .res1080p: return .hd1920x1080
        case .res720p: return .hd1280x720
        case .res480p: return .vga640x480
        }
    }

    public static func from(string: String) -> StreamResolution {
        let lower = string.lowercased()
        if lower.contains("4k") || lower.contains("3840") {
            return .res4K
        } else if lower.contains("720") {
            return .res720p
        } else if lower.contains("480") {
            return .res480p
        } else {
            return .res1080p
        }
    }
}

public enum StreamFps: Int, CaseIterable, Identifiable {
    case fps24 = 24
    case fps30 = 30
    case fps60 = 60

    public var id: Int { rawValue }
    public var label: String { "\(rawValue) FPS" }
}

