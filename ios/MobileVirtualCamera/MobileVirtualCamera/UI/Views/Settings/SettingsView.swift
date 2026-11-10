import SwiftUI

// MARK: - Settings View
public struct SettingsView: View {
    @ObservedObject private var prefs = UserPreferences.shared
    @ObservedObject private var authService = AuthService.shared
    @State private var showingInstructions: Bool = false
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Server Connection Section
                        serverSection

                        // Video Encoding Section
                        videoSection

                        // Audio Section
                        audioSection

                        // Background & System Section
                        systemSection

                        // Account Section
                        accountSection

                        // Help & Guide Section
                        helpSection

                        // App Version Footer
                        VStack(spacing: 4) {
                            Text("Mobile Virtual Camera for iOS")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppTheme.textSecondary)
                            Text("Version 1.0.0 (Build 1)")
                                .font(.system(size: 11))
                                .foregroundColor(AppTheme.textMuted)
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 24)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.primaryLight)
                    .fontWeight(.bold)
                }
            }
            .sheet(isPresented: $showingInstructions) {
                InstructionsView()
            }
        }
    }

    // MARK: - Sections
    private var serverSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("SERVER CONNECTION", systemImage: "server.rack")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.primaryLight)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Backend / Relay Server URL")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)

                    TextField("http://192.168.1.100:5000", text: $prefs.serverBaseUrl)
                        .font(.system(size: 14, design: .monospaced))
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding(10)
                        .background(AppTheme.surface)
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
            }
        }
    }

    private var videoSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Label("VIDEO ENCODING & STREAMING", systemImage: "video.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.primaryLight)

                // Resolution Picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("Default Resolution")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)

                    Picker("Resolution", selection: $prefs.defaultResolution) {
                        Text("4K UHD (3840x2160)").tag("4K")
                        Text("1080p FHD (1920x1080)").tag("1080p")
                        Text("720p HD (1280x720)").tag("720p")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                // FPS Picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("Default Frame Rate")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)

                    Picker("FPS", selection: $prefs.defaultFps) {
                        Text("24 FPS").tag(24)
                        Text("30 FPS").tag(30)
                        Text("60 FPS").tag(60)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                // Bitrate Slider
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Target Bitrate")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                        Spacer()
                        Text("\(prefs.targetBitrateKbps / 1000) Mbps")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(AppTheme.liveGreen)
                    }

                    Slider(
                        value: Binding(
                            get: { Double(prefs.targetBitrateKbps) },
                            set: { prefs.targetBitrateKbps = Int($0) }
                        ),
                        in: 1000...20000,
                        step: 500
                    )
                    .accentColor(AppTheme.primary)
                }

                Toggle(isOn: $prefs.useH265Codec) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("HEVC / H.265 Hardware Compression")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Reduces bandwidth usage by up to 40% with Apple Silicon encoder")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textMuted)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: AppTheme.primary))

                Toggle(isOn: $prefs.enableVideoStabilization) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cinematic Video Stabilization")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Smoothes hand jitter and vibration using gyroscope")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textMuted)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: AppTheme.primary))
            }
        }
    }

    private var audioSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("AUDIO CAPTURE", systemImage: "mic.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.primaryLight)

                Toggle(isOn: $prefs.isAudioEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Stream Microphone Audio")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Sends uncompressed high-fidelity stereo audio to your PC")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textMuted)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: AppTheme.primary))
            }
        }
    }

    private var systemSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("BACKGROUND STREAMING & DEVICE", systemImage: "iphone")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.primaryLight)

                Toggle(isOn: $prefs.backgroundStreamingEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Keep Streaming When App is Backgrounded")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Maintains WebRTC audio/video relay while using other apps")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textMuted)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: AppTheme.primary))

                Divider().background(AppTheme.border)

                HStack {
                    Text("Device ID")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textMuted)
                    Spacer()
                    Text(prefs.deviceId)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
    }

    private var helpSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("HELP & DOCUMENTATION", systemImage: "book.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.primaryLight)

                Button(action: { showingInstructions = true }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Open In-App Instructions & Setup Guide")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Quick start, Zoom/Teams setup, performance tips & FAQ")
                                .font(.system(size: 11))
                                .foregroundColor(AppTheme.textMuted)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
        }
    }

    private var accountSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("ACCOUNT", systemImage: "person.crop.circle")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.primaryLight)

                if let user = authService.currentUser {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            Text(user.email)
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        Spacer()
                    }

                    Button(action: {
                        authService.logout()
                        dismiss()
                    }) {
                        Text("Sign Out")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.danger)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(AppTheme.danger.opacity(0.12))
                            .cornerRadius(10)
                    }
                } else {
                    Text("Not signed in")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
    }
}

