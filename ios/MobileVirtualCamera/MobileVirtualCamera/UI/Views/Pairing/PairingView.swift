import SwiftUI

// MARK: - Pairing View
public struct PairingView: View {
    @StateObject private var viewModel = PairingViewModel()
    @State private var scanMode: Int = 0 // 0 = QR Scanner, 1 = Manual PIN
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 20) {
                // Top Header Bar
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Device Pairing")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Connect your iPhone to your desktop computer")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.textMuted)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Mode Picker Segmented Control
                Picker("Pairing Mode", selection: $scanMode) {
                    Text("Scan QR Code").tag(0)
                    Text("Enter Code").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 20)

                // Feedback Banners
                if let error = viewModel.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppTheme.danger)
                        Text(error)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.danger)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.danger.opacity(0.15))
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                }

                if let success = viewModel.successMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.liveGreen)
                        Text(success)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.liveGreen)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.liveGreen.opacity(0.15))
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                }

                if scanMode == 0 {
                    // QR Code Scanner View with viewfinder overlay
                    ZStack {
                        QRScannerView { code in
                            viewModel.handleScannedCode(code)
                        }
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(AppTheme.border, lineWidth: 2)
                        )

                        // Target Box
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.primary, lineWidth: 3)
                            .frame(width: 240, height: 240)
                            .shadow(color: AppTheme.primary.opacity(0.6), radius: 10)

                        VStack {
                            Spacer()
                            Text("Point camera at Desktop QR code")
                                .font(.system(size: 13, weight: .semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.75))
                                .cornerRadius(20)
                                .foregroundColor(.white)
                                .padding(.bottom, 20)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 340)
                    .padding(.horizontal, 20)
                } else {
                    // Manual PIN Entry
                    ManualPairingView(
                        pairCode: $viewModel.pairCodeInput,
                        isLoading: viewModel.isLoading,
                        onSubmit: { viewModel.submitPairCode(code: viewModel.pairCodeInput) }
                    )
                    .padding(.horizontal, 20)
                }

                // Paired Devices List
                if !viewModel.pairedDevices.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PAIRED COMPUTERS")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppTheme.textMuted)
                            .padding(.horizontal, 20)

                        ScrollView {
                            VStack(spacing: 10) {
                                ForEach(viewModel.pairedDevices) { device in
                                    HStack {
                                        Image(systemName: device.targetPlatform.lowercased() == "windows" ? "display" : "laptopcomputer")
                                            .font(.system(size: 20))
                                            .foregroundColor(AppTheme.primaryLight)
                                            .frame(width: 36, height: 36)
                                            .background(AppTheme.surface)
                                            .cornerRadius(8)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(device.targetDeviceName)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(AppTheme.textPrimary)
                                            Text(device.targetPlatform.capitalized)
                                                .font(.system(size: 11))
                                                .foregroundColor(AppTheme.textSecondary)
                                        }

                                        Spacer()

                                        Button(action: { viewModel.unpair(pairingId: device.id) }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(AppTheme.danger)
                                                .font(.system(size: 14))
                                        }
                                    }
                                    .padding(12)
                                    .background(AppTheme.card)
                                    .cornerRadius(12)
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                    }
                }

                Spacer()
            }
        }
    }
}

