import SwiftUI

// MARK: - Instruction Category
public enum InstructionCategory: String, CaseIterable, Identifiable {
    case quickStart = "Quick Start"
    case desktopApps = "Apps & Zoom"
    case proControls = "Pro Controls"
    case batteryTips = "Performance"
    case troubleshooting = "Help & FAQ"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .quickStart: return "bolt.fill"
        case .desktopApps: return "display.2"
        case .proControls: return "camera.badge.ellipsis"
        case .batteryTips: return "battery.100.bolt"
        case .troubleshooting: return "questionmark.circle.fill"
        }
    }
}

// MARK: - In-App Instructions View
public struct InstructionsView: View {
    @State private var selectedCategory: InstructionCategory = .quickStart
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Category Tab Bar
                    categoryTabBar
                        .padding(.vertical, 12)
                        .background(AppTheme.secondaryBackground)

                    // Content Area
                    ScrollView {
                        VStack(spacing: 20) {
                            switch selectedCategory {
                            case .quickStart:
                                quickStartSection
                            case .desktopApps:
                                desktopAppsSection
                            case .proControls:
                                proControlsSection
                            case .batteryTips:
                                batteryTipsSection
                            case .troubleshooting:
                                troubleshootingSection
                            }

                            Spacer(minLength: 30)
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Instructions & Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.primaryLight)
                    .fontWeight(.bold)
                }
            }
        }
    }

    // MARK: - Category Tab Bar
    private var categoryTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(InstructionCategory.allCases) { cat in
                    let isSelected = selectedCategory == cat
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = cat
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: cat.iconName)
                                .font(.system(size: 13, weight: .bold))
                            Text(cat.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(isSelected ? AppTheme.primary : AppTheme.surface)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? AppTheme.primaryLight : AppTheme.border, lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - 1. Quick Start Section
    private var quickStartSection: some View {
        VStack(spacing: 16) {
            guideBanner(
                title: "How to Connect in 3 Easy Steps",
                subtitle: "Turn your iPhone into a wireless webcam in seconds",
                icon: "sparkles"
            )

            stepCard(
                step: 1,
                title: "Open the Desktop App on your PC or Mac",
                description: "Launch Mobile Virtual Camera on your computer. Make sure both your iPhone and your computer are connected to the same Wi-Fi network.",
                icon: "laptopcomputer.and.arrow.down"
            )

            stepCard(
                step: 2,
                title: "Scan the Pairing QR Code",
                description: "In this iOS app, tap the QR Scanner icon at the top right of the camera screen. Point your camera at the QR code shown on your desktop screen.",
                icon: "qrcode.viewfinder"
            )

            stepCard(
                step: 3,
                title: "You're Live!",
                description: "Your live video will immediately stream to your PC. Select 'Mobile Virtual Camera' in Zoom, Teams, Meet, or OBS to start using it.",
                icon: "video.fill"
            )

            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "wifi")
                            .foregroundColor(AppTheme.liveGreen)
                        Text("Wi-Fi Tip")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Text("For sub-20ms ultra-low latency, connect both your phone and PC to a 5 GHz Wi-Fi network, or connect your PC via Ethernet cable to the same router.")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
    }

    // MARK: - 2. Desktop Apps & Zoom Section
    private var desktopAppsSection: some View {
        VStack(spacing: 16) {
            guideBanner(
                title: "Using with Video & Streaming Software",
                subtitle: "Mobile Virtual Camera appears as a standard webcam in all apps",
                icon: "video.badge.checkmark"
            )

            appConfigCard(
                appName: "Zoom Meetings",
                icon: "video.bubble.fill",
                color: Color(hex: "#2D8CFF"),
                steps: [
                    "Open Zoom and click your profile picture > Settings (gear icon)",
                    "Select Video from the left sidebar",
                    "Under Camera, choose 'Mobile Virtual Camera'",
                    "Check 'HD' and 'Enable hardware acceleration' for best quality"
                ]
            )

            appConfigCard(
                appName: "Microsoft Teams",
                icon: "person.3.fill",
                color: Color(hex: "#505AC9"),
                steps: [
                    "In Teams, click the three dots (...) next to your avatar > Settings",
                    "Click Devices on the left",
                    "Scroll down to Camera and select 'Mobile Virtual Camera'",
                    "Check the preview window to confirm your iPhone feed is streaming"
                ]
            )

            appConfigCard(
                appName: "Google Meet & Chrome",
                icon: "globe",
                color: Color(hex: "#00832D"),
                steps: [
                    "Join or start a Google Meet meeting",
                    "Click More options (three vertical dots) > Settings",
                    "Click Video in the left menu",
                    "Set Camera to 'Mobile Virtual Camera'",
                    "Set Send Resolution to 'Maximum (1080p)'"
                ]
            )

            appConfigCard(
                appName: "OBS Studio",
                icon: "dot.radiowaves.left.and.right",
                color: Color(hex: "#9F75FF"),
                steps: [
                    "Under Sources, click the + button > Video Capture Device",
                    "Name it 'iPhone Virtual Camera' and click OK",
                    "In the Device dropdown, choose 'Mobile Virtual Camera'",
                    "Set Resolution/FPS Type to 'Custom' and pick 1920x1080 @ 60 FPS"
                ]
            )

            appConfigCard(
                appName: "Discord",
                icon: "bubble.left.and.bubble.right.fill",
                color: Color(hex: "#5865F2"),
                steps: [
                    "Click User Settings (gear icon) > Voice & Video",
                    "Scroll down to Video Settings",
                    "Select 'Mobile Virtual Camera' in the Camera dropdown",
                    "Click 'Test Video' to see your live high-res camera feed"
                ]
            )
        }
    }

    // MARK: - 3. Pro Controls Section
    private var proControlsSection: some View {
        VStack(spacing: 16) {
            guideBanner(
                title: "Camera Controls & Pro Capabilities",
                subtitle: "Unlock studio-grade video right from your phone",
                icon: "camera.filters"
            )

            featureExplanationCard(
                icon: "camera.aperture",
                title: "Multi-Lens Switching",
                description: "Tap '.5' for Ultra-Wide (great for whiteboards or wide rooms), '1x' for Standard Wide, '3x' for portrait Telephoto, or 'Front' for face selfie mode."
            )

            featureExplanationCard(
                icon: "hand.tap.fill",
                title: "Tap to Focus & Exposure Lock",
                description: "Tap anywhere on the live camera preview to center auto-focus and exposure on that exact point. An animated targeting reticle confirms focus lock."
            )

            featureExplanationCard(
                icon: "arrow.up.left.and.down.right.magnifyingglass",
                title: "Smooth Pinch-to-Zoom",
                description: "Use two fingers on the camera screen to smoothly zoom in and out with optical and digital zoom interpolation up to 10x magnification."
            )

            featureExplanationCard(
                icon: "flashlight.on.fill",
                title: "Flashlight / Studio Torch",
                description: "Tap the flashlight icon in the bottom dock whenever you are streaming in low-light environments to brighten your face with soft fill lighting."
            )

            featureExplanationCard(
                icon: "camera.viewfinder",
                title: "High-Resolution Snapshot",
                description: "Tap the large white shutter button at the bottom of the viewfinder to capture a full-resolution 48MP/12MP photo to your gallery while streaming."
            )

            featureExplanationCard(
                icon: "gyroscope",
                title: "Cinematic Video Stabilization",
                description: "Uses your iPhone's built-in 6-axis gyroscope to eliminate hand tremors, desk vibrations, and walking movement automatically."
            )
        }
    }

    // MARK: - 4. Performance & Battery Section
    private var batteryTipsSection: some View {
        VStack(spacing: 16) {
            guideBanner(
                title: "Thermal & Battery Optimization",
                subtitle: "Keep your iPhone cool during hours-long meetings",
                icon: "thermometer.sun.fill"
            )

            tipCard(
                icon: "bolt.badge.checkmark.fill",
                color: AppTheme.liveGreen,
                title: "Use a MagSafe or Wireless Charging Stand",
                content: "Video encoding and streaming utilize both the Neural Engine and GPU. Keeping your device on a MagSafe charger ensures your battery never drops during long streams."
            )

            tipCard(
                icon: "cpu.fill",
                color: AppTheme.primaryLight,
                title: "Enable HEVC / H.265 Hardware Compression",
                content: "In Settings, toggle 'HEVC Hardware Compression'. Apple Silicon Bionic chips have dedicated hardware HEVC encoders that cut battery usage by 35% compared to software encoding."
            )

            tipCard(
                icon: "sun.min.fill",
                color: AppTheme.warning,
                title: "Lower Screen Brightness",
                content: "During continuous streaming, your iPhone screen remains on to display the HUD. Dimming your iPhone's screen brightness dramatically lowers device temperatures."
            )

            tipCard(
                icon: "antenna.radiowaves.left.and.right",
                color: AppTheme.primary,
                title: "Use 5 GHz Wi-Fi instead of 2.4 GHz",
                content: "2.4 GHz Wi-Fi is crowded with Bluetooth interference and microwave signals. 5 GHz Wi-Fi provides 4x greater bandwidth with virtually zero packet loss."
            )
        }
    }

    // MARK: - 5. Troubleshooting Section
    private var troubleshootingSection: some View {
        VStack(spacing: 16) {
            guideBanner(
                title: "Frequently Asked Questions & Troubleshooting",
                subtitle: "Solutions for common connection and streaming questions",
                icon: "wrench.and.screwdriver.fill"
            )

            faqCard(
                question: "The Desktop app is not showing in my video meeting app (Zoom / Teams / OBS)?",
                answer: "1. Make sure you installed the Virtual Camera Driver by running setup-windows.ps1 or opening the Desktop app as Administrator once.\n2. Restart Zoom or Teams so it refreshes its camera hardware list.\n3. Verify in the Desktop app dashboard that 'Virtual Camera Active' shows green."
            )

            faqCard(
                question: "QR code scanner is not pairing with Desktop?",
                answer: "1. Ensure both devices are on the exact same Wi-Fi network.\n2. In the iOS app, tap 'Enter Code' tab and manually enter the 6-character code shown below the QR code on Desktop.\n3. Check that Windows Firewall is not blocking port 5000 on your PC."
            )

            faqCard(
                question: "Video is lagging or stuttering?",
                answer: "1. Switch your resolution from 4K to 1080p or 720p in the top bar menu.\n2. Lower target bitrate in Settings to 3 Mbps or 4 Mbps.\n3. Make sure you are connected to a 5 GHz Wi-Fi router rather than 2.4 GHz."
            )

            faqCard(
                question: "Can I stream while my iPhone is locked or in another app?",
                answer: "Yes! In Settings, ensure 'Keep Streaming When App is Backgrounded' is toggled ON. The app runs a background audio/video service to maintain your WebRTC stream."
            )
        }
    }

    // MARK: - Helper Views
    private func guideBanner(title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundColor(AppTheme.primaryLight)
                .frame(width: 48, height: 48)
                .background(AppTheme.primary.opacity(0.18))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(AppTheme.card)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private func stepCard(step: Int, title: String, description: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.primaryGradient)
                    .frame(width: 34, height: 34)
                Text("\(step)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineSpacing(2)
            }
            Spacer()
        }
        .padding(14)
        .background(AppTheme.card)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private func appConfigCard(appName: String, icon: String, color: Color, steps: [String]) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(color)
                    Text(appName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(color)
                            Text(step)
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private func featureExplanationCard(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(AppTheme.primaryLight)
                .frame(width: 36, height: 36)
                .background(AppTheme.surface)
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(12)
        .background(AppTheme.card)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private func tipCard(icon: String, color: Color, title: String, content: String) -> some View {
        GlassCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text(content)
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                        .lineSpacing(2)
                }
            }
        }
    }

    private func faqCard(question: String, answer: String) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    Text("Q:")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppTheme.primaryLight)
                    Text(question)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }

                HStack(alignment: .top, spacing: 8) {
                    Text("A:")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppTheme.liveGreen)
                    Text(answer)
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                        .lineSpacing(2)
                }
            }
        }
    }
}

