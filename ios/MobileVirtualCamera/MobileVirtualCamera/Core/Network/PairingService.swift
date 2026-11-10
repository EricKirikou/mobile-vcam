import Foundation

// MARK: - Pairing Service
public final class PairingService: ObservableObject {
    public static let shared = PairingService()

    @Published public var pairedDevices: [PairedDevice] = []
    @Published public var activePairing: PairingResponse?
    @Published public var isPairing: Bool = false

    private let apiClient: APIClient

    private init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    @MainActor
    public func claimPairCode(pairCode: String, customServerUrl: String? = nil) async throws -> PairingResponse {
        isPairing = true
        defer { isPairing = false }

        let payload = PairingRequest(
            pairCode: pairCode.uppercased().trimmingCharacters(in: .whitespacesAndNewlines),
            deviceId: UserPreferences.shared.deviceId,
            deviceName: UserPreferences.shared.deviceName,
            platform: "ios"
        )

        let response: PairingResponse = try await apiClient.request(
            endpoint: .claimPairCode,
            body: payload,
            customBaseURL: customServerUrl
        )

        self.activePairing = response
        try await fetchPairedDevices()
        return response
    }

    @MainActor
    public func fetchPairedDevices() async throws {
        struct ListPairingsResponse: Decodable {
            let success: Bool
            let pairings: [PairedDevice]
        }

        do {
            let res: ListPairingsResponse = try await apiClient.request(endpoint: .getPairings)
            self.pairedDevices = res.pairings
        } catch {
            // Handle error or offline state
            print("Failed to fetch pairings: \(error.localizedDescription)")
        }
    }

    @MainActor
    public func unpairDevice(pairingId: String) async throws {
        struct GenericResponse: Decodable {
            let success: Bool
        }
        let _: GenericResponse = try await apiClient.request(endpoint: .unpairDevice(pairingId))
        self.pairedDevices.removeAll { $0.id == pairingId }
    }
}

