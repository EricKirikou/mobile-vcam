import Foundation

// MARK: - API Client Errors
public enum APIError: LocalizedError {
    case invalidURL
    case serializationError
    case unauthorized
    case serverError(statusCode: Int, message: String)
    case networkError(Error)
    case decodingError(Error)
    case custom(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API server URL."
        case .serializationError:
            return "Failed to serialize request body."
        case .unauthorized:
            return "Session expired or invalid credentials. Please log in again."
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .networkError(let error):
            return "Network connection error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .custom(let message):
            return message
        }
    }
}

// MARK: - API Client
public final class APIClient {
    public static let shared = APIClient()
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15.0
        config.timeoutIntervalForResource = 30.0
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    public func request<T: Decodable>(
        endpoint: APIEndpoint,
        body: Encodable? = nil,
        customBaseURL: String? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        let baseURL = customBaseURL ?? UserPreferences.shared.serverBaseUrl
        guard let url = URL(string: baseURL + endpoint.path) else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue(UserPreferences.shared.deviceId, forHTTPHeaderField: "X-Device-ID")

        // Attach Authorization Bearer token if available
        if let token = KeychainHelper.shared.readString(key: "auth_token") {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Additional headers
        headers?.forEach { key, value in
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        // Attach body
        if let body = body {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                urlRequest.httpBody = try encoder.encode(body)
            } catch {
                throw APIError.serializationError
            }
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.custom("Unknown response format received from server.")
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorMsg)
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}

