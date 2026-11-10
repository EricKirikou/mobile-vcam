import SwiftUI
import AVFoundation

// MARK: - Camera Stream View
public struct CameraStreamView: View {
    @StateObject private var viewModel = CameraViewModel()
    @State private var currentZoomScale: CGFloat = 1.0

    public init() {}

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if viewModel.cameraManager.authorizationStatus == .authorized {
                // Live Viewfinder
                CameraPreviewView(cameraManager: viewModel.cameraManager)
                    .ignoresSafeArea()
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / currentZoomScale
                                currentZoomScale = value
                                let targetZoom = viewModel.cameraManager.controls.zoomFactor * delta
                                viewModel.cameraManager.setZoom(factor: targetZoom)
                            }
                            .onEnded { _ in
                                currentZoomScale = 1.0
                            }
                    )

                // White Snapshot Flash Overlay
                if viewModel.showPhotoSnapshotFlash {
                    Color.white.ignoresSafeArea()
                        .transition(.opacity)
                }

                // HUD Overlays
                VStack {
                    // Top Navigation Bar
                    topBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    // Real-Time Telemetry Badges
                    MetricsOverlayView(
                        metrics: viewModel.webRtcClient.metrics,
                        batteryLevel: TelemetryCollector.shared.currentTelemetry?.batteryLevel ?? 100,
                        isCharging: TelemetryCollector.shared.currentTelemetry?.isCharging ?? false
                    )
                    .padding(.top, 6)

                    Spacer()

                    // Bottom Floating Quick Controls
                    QuickControlsOverlay(
                        cameraManager: viewModel.cameraManager,
                        onToggleMute: { viewModel.toggleMute() },
                        onTakePhoto: { viewModel.capturePhoto() },
                        onToggleTorch: { viewModel.toggleTorch() },
                        onSwitchLens: { lens in viewModel.switchLens(lens) }
                    )
                    .padding(.bottom, 24)
                }
            } else {
                // Permission Denied or Pending View
                permissionPromptView
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .sheet(isPresented: $viewModel.showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $viewModel.showingPairing) {
            PairingView()
        }
        .sheet(isPresented: $viewModel.showingInstructions) {
            InstructionsView()
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack(spacing: 12) {
            // Live Status Pill
            let isStreaming = viewModel.webRtcClient.state == .streaming
            StatusBadge(
                isLive: isStreaming,
                text: isStreaming ? "LIVE" : viewModel.signalingClient.isConnected ? "READY" : "CONNECTING"
            )

            // Current Resolution & FPS Pill
            Menu {
                ForEach(StreamResolution.allCases) { res in
                    Button(res.rawValue) {
                        viewModel.cameraManager.changeResolution(res)
                    }
                }
                Divider()
                ForEach(StreamFps.allCases) { fps in
                    Button(fps.label) {
                        viewModel.cameraManager.changeFps(fps)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text("\(viewModel.cameraManager.controls.resolution.shortName) • \(viewModel.cameraManager.controls.fps.rawValue)P")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.6))
                .cornerRadius(12)
            }

            Spacer()

            // Instructions / Help Button
            Button(action: { viewModel.showingInstructions = true }) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }

            // Pair Device Button
            Button(action: { viewModel.showingPairing = true }) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }

            // Settings Button
            Button(action: { viewModel.showingSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Permission Prompt
    private var permissionPromptView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 54))
                .foregroundColor(AppTheme.primary)

            Text("Camera & Microphone Access Required")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text("Mobile Virtual Camera needs permission to access your camera and microphone to stream high-definition video to your desktop.")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            GlowingButton(title: "Grant Permission", icon: "checkmark.shield") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .frame(maxWidth: 240)
        }
        .padding(32)
    }
}

