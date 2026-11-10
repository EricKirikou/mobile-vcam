import SwiftUI

// MARK: - Quick Controls Overlay
public struct QuickControlsOverlay: View {
    @ObservedObject var cameraManager: CameraManager
    let onToggleMute: () -> Void
    let onTakePhoto: () -> Void
    let onToggleTorch: () -> Void
    let onSwitchLens: (CameraLensType) -> Void

    public init(
        cameraManager: CameraManager = .shared,
        onToggleMute: @escaping () -> Void,
        onTakePhoto: @escaping () -> Void,
        onToggleTorch: @escaping () -> Void,
        onSwitchLens: @escaping (CameraLensType) -> Void
    ) {
        self.cameraManager = cameraManager
        self.onToggleMute = onToggleMute
        self.onTakePhoto = onTakePhoto
        self.onToggleTorch = onToggleTorch
        self.onSwitchLens = onSwitchLens
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Lens Switcher Pill Bar (0.5x, 1x, 3x, Front)
            HStack(spacing: 6) {
                ForEach(cameraManager.availableLenses) { lens in
                    let isSelected = cameraManager.controls.currentLens == lens
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        onSwitchLens(lens)
                    }) {
                        Text(lensShortcutLabel(lens))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(isSelected ? .black : .white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSelected ? Color.white : Color.black.opacity(0.5))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(4)
            .background(Color.black.opacity(0.4))
            .clipShape(Capsule())

            // Main Action Dock
            HStack(spacing: 24) {
                // Torch Button
                if cameraManager.controls.hasTorch {
                    dockButton(
                        icon: cameraManager.controls.isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill",
                        active: cameraManager.controls.isTorchOn,
                        action: onToggleTorch
                    )
                }

                // Audio Mute Button
                dockButton(
                    icon: cameraManager.controls.isMuted ? "mic.slash.fill" : "mic.fill",
                    active: !cameraManager.controls.isMuted,
                    action: onToggleMute
                )

                // High-Res Snapshot Capture Button
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    onTakePhoto()
                }) {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 60, height: 60)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 50, height: 50)
                    }
                }

                // Camera Flip Shortcut (Front <-> Back)
                dockButton(
                    icon: "camera.rotate.fill",
                    active: false,
                    action: {
                        let next: CameraLensType = cameraManager.controls.currentLens == .front ? .wide : .front
                        onSwitchLens(next)
                    }
                )
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Color.black.opacity(0.65))
            .cornerRadius(32)
            .overlay(
                RoundedRectangle(cornerRadius: 32)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
        }
    }

    private func dockButton(icon: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(active ? AppTheme.liveGreen : .white)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.12))
                .clipShape(Circle())
        }
    }

    private func lensShortcutLabel(_ lens: CameraLensType) -> String {
        switch lens {
        case .ultraWide: return ".5"
        case .wide: return "1x"
        case .telephoto: return "3x"
        case .front: return "Front"
        }
    }
}

