import SwiftUI

// MARK: - App Colors & Design System
public struct AppTheme {
    public static let background = Color(hex: "#0F0F23")
    public static let secondaryBackground = Color(hex: "#16162A")
    public static let surface = Color(hex: "#1E1E38")
    public static let card = Color(hex: "#1A1A32")
    public static let border = Color(hex: "#2E2E52")

    // Accents
    public static let primary = Color(hex: "#6C63FF")
    public static let primaryLight = Color(hex: "#8B84FF")
    public static let primaryGradient = LinearGradient(
        colors: [Color(hex: "#6C63FF"), Color(hex: "#9F75FF")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let liveGreen = Color(hex: "#00FF88")
    public static let liveGradient = LinearGradient(
        colors: [Color(hex: "#00FF88"), Color(hex: "#00D26A")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let warning = Color(hex: "#FFB020")
    public static let danger = Color(hex: "#FF4D6D")

    // Text
    public static let textPrimary = Color(hex: "#FFFFFF")
    public static let textSecondary = Color(hex: "#A0A0C0")
    public static let textMuted = Color(hex: "#64648C")
}

// MARK: - Color Hex Initializer
extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

