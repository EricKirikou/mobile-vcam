import Foundation
import SwiftUI

// MARK: - Pairing ViewModel
public final class PairingViewModel: ObservableObject {
    @Published public var pairCodeInput: String = ""
    @Published public var isScanning: Bool = true
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var successMessage: String? = nil
    @Published public var pairedDevices: [PairedDevice] = []

    private let pairingService = PairingService.shared

    public init() {
        self.pairedDevices = pairingService.pairedDevices
    }

    @MainActor
    public func handleScannedCode(_ rawCode: String) {
        // Prevent duplicate calls while loading
        guard !isLoading else { return }

        // Check if rawCode is JSON QRCodePairingPayload
        if let data = rawCode.data(using: .utf8),
           let payload = try? JSONDecoder().decode(QRCodePairingPayload.self, from: data) {
            submitPairCode(code: payload.pairCode, customServerUrl: payload.serverUrl)
        } else {
            // Assume direct pairCode string
            submitPairCode(code: rawCode.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    @MainActor
    public func submitPairCode(code: String, customServerUrl: String? = nil) {
        guard !code.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        successMessage = nil

        Task {
            do {
                let response = try await pairingService.claimPairCode(pairCode: code, customServerUrl: customServerUrl)
                let desktopName = response.desktopDeviceName ?? "Desktop"
                self.successMessage = "Successfully paired with \(desktopName)!"
                self.pairedDevices = pairingService.pairedDevices
                self.pairCodeInput = ""
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    @MainActor
    public func unpair(pairingId: String) {
        Task {
            do {
                try await pairingService.unpairDevice(pairingId: pairingId)
                self.pairedDevices = pairingService.pairedDevices
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

