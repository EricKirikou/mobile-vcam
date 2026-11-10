import SwiftUI

// MARK: - App Navigation Root
public struct AppNavigation: View {
    @ObservedObject private var authService = AuthService.shared
    @State private var isInitializing: Bool = true

    public init() {}

    public var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if isInitializing {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryLight))
                        .scaleEffect(1.4)
                    Text("Loading Mobile Virtual Camera...")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
            } else {
                if authService.isAuthenticated {
                    CameraStreamView()
                        .transition(.opacity)
                } else {
                    LoginView()
                        .transition(.opacity)
                }
            }
        }
        .onAppear {
            Task {
                _ = await authService.restoreSession()
                withAnimation {
                    isInitializing = false
                }
            }
        }
    }
}

