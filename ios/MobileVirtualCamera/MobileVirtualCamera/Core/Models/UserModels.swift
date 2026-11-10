import Foundation

// MARK: - User Models

public struct User: Codable, Identifiable {
    public let id: String
    public let email: String
    public let name: String
    public let createdAt: Date?
    public let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case email
        case name
        case createdAt
        case updatedAt
    }

    public init(id: String, email: String, name: String, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct AuthTokens: Codable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: Int?

    public init(accessToken: String, refreshToken: String, expiresIn: Int? = 3600) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
    }
}

public struct AuthResponse: Codable {
    public let success: Bool
    public let message: String?
    public let token: String?
    public let refreshToken: String?
    public let user: User?

    public init(success: Bool, message: String? = nil, token: String? = nil, refreshToken: String? = nil, user: User? = nil) {
        self.success = success
        self.message = message
        self.token = token
        self.refreshToken = refreshToken
        self.user = user
    }
}

