import Foundation
import SwiftUI

// MARK: - Auth ViewModel
public final class AuthViewModel: ObservableObject {
    @Published public var email: String = ""
    @Published public var password: String = ""
    @Published public var name: String = ""
    @Published public var isRegistering: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil

    private let authService = AuthService.shared

    public init() {}

    @MainActor
    public func submit() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                if isRegistering {
                    guard !name.isEmpty else {
                        errorMessage = "Please enter your name."
                        isLoading = false
                        return
                    }
                    _ = try await authService.register(email: email, password: password, name: name)
                } else {
                    _ = try await authService.login(email: email, password: password)
                }
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

