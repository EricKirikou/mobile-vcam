import Foundation

// MARK: - Auth Service
public final class AuthService: ObservableObject {
    public static let shared = AuthService()

    @Published public var currentUser: User?
    @Published public var isAuthenticated: Bool = false
    @Published public var isLoading: Bool = false

    private let apiClient: APIClient
    private let keychain: KeychainHelper

    private init(apiClient: APIClient = .shared, keychain: KeychainHelper = .shared) {
        self.apiClient = apiClient
        self.keychain = keychain
        self.isAuthenticated = keychain.readString(key: "auth_token") != nil
    }

    public struct LoginPayload: Encodable {
        public let email: String
        public let password: String
    }

    public struct RegisterPayload: Encodable {
        public let email: String
        public let password: String
        public let name: String
    }

    @MainActor
    public func login(email: String, password: String) async throws -> User {
        isLoading = true
        defer { isLoading = false }

        let payload = LoginPayload(email: email, password: password)
        let response: AuthResponse = try await apiClient.request(endpoint: .login, body: payload)

        guard let token = response.token, let user = response.user else {
            throw APIError.custom(response.message ?? "Authentication failed.")
        }

        _ = keychain.save(key: "auth_token", string: token)
        if let refreshToken = response.refreshToken {
            _ = keychain.save(key: "refresh_token", string: refreshToken)
        }
        _ = keychain.save(key: "user_id", string: user.id)

        self.currentUser = user
        self.isAuthenticated = true
        return user
    }

    @MainActor
    public func register(email: String, password: String, name: String) async throws -> User {
        isLoading = true
        defer { isLoading = false }

        let payload = RegisterPayload(email: email, password: password, name: name)
        let response: AuthResponse = try await apiClient.request(endpoint: .register, body: payload)

        guard let token = response.token, let user = response.user else {
            throw APIError.custom(response.message ?? "Registration failed.")
        }

        _ = keychain.save(key: "auth_token", string: token)
        if let refreshToken = response.refreshToken {
            _ = keychain.save(key: "refresh_token", string: refreshToken)
        }

        self.currentUser = user
        self.isAuthenticated = true
        return user
    }

    @MainActor
    public func restoreSession() async -> Bool {
        guard keychain.readString(key: "auth_token") != nil else {
            self.isAuthenticated = false
            return false
        }

        do {
            struct MeResponse: Decodable {
                let success: Bool
                let user: User
            }
            let res: MeResponse = try await apiClient.request(endpoint: .getMe)
            self.currentUser = res.user
            self.isAuthenticated = true
            return true
        } catch {
            // Token might be expired
            keychain.clearAll()
            self.currentUser = nil
            self.isAuthenticated = false
            return false
        }
    }

    @MainActor
    public func logout() {
        keychain.clearAll()
        self.currentUser = nil
        self.isAuthenticated = false
    }
}

