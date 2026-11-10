import SwiftUI

// MARK: - Login & Authentication View
public struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @ObservedObject private var prefs = UserPreferences.shared
    @State private var showServerConfig: Bool = false
    @State private var showingInstructions: Bool = false

    public init() {}

    public var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    Spacer(minLength: 40)

                    // App Logo & Branding
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.primaryGradient)
                                .frame(width: 80, height: 80)
                                .shadow(color: AppTheme.primary.opacity(0.5), radius: 20)

                            Image(systemName: "video.badge.waveform.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                        }

                        Text("Mobile Virtual Camera")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)

                        Text("Use your iPhone as an ultra high-definition webcam for your desktop PC or Mac")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        Button(action: { showingInstructions = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 13))
                                Text("How it works & Setup Guide")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(AppTheme.primaryLight)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(AppTheme.surface)
                            .clipShape(Capsule())
                        }
                        .padding(.top, 2)
                    }

                    // Error Message
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
                        .padding(.horizontal, 24)
                    }

                    // Form Card
                    GlassCard {
                        VStack(spacing: 16) {
                            if viewModel.isRegistering {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Full Name")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(AppTheme.textSecondary)

                                    TextField("Alex Miller", text: $viewModel.name)
                                        .padding(12)
                                        .background(AppTheme.surface)
                                        .cornerRadius(10)
                                        .foregroundColor(.white)
                                }
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email Address")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppTheme.textSecondary)

                                TextField("alex@example.com", text: $viewModel.email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .padding(12)
                                    .background(AppTheme.surface)
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Password")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppTheme.textSecondary)

                                SecureField("••••••••", text: $viewModel.password)
                                    .padding(12)
                                    .background(AppTheme.surface)
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                            }

                            GlowingButton(
                                title: viewModel.isRegistering ? "Create Account" : "Sign In",
                                icon: viewModel.isRegistering ? "person.badge.plus" : "arrow.right.circle.fill",
                                isLoading: viewModel.isLoading,
                                action: { viewModel.submit() }
                            )
                            .padding(.top, 8)

                            Button(action: {
                                withAnimation {
                                    viewModel.isRegistering.toggle()
                                    viewModel.errorMessage = nil
                                }
                            }) {
                                Text(viewModel.isRegistering ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AppTheme.primaryLight)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Server Configuration Disclosure
                    DisclosureGroup(isExpanded: $showServerConfig) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Relay Server URL")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AppTheme.textMuted)

                            TextField("http://192.168.1.100:5000", text: $prefs.serverBaseUrl)
                                .font(.system(size: 13, design: .monospaced))
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding(10)
                                .background(AppTheme.surface)
                                .cornerRadius(8)
                                .foregroundColor(.white)
                        }
                        .padding(.top, 8)
                    } label: {
                        HStack {
                            Image(systemName: "network")
                            Text("Server Settings (\(prefs.serverBaseUrl))")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.horizontal, 28)

                    Spacer(minLength: 40)
                }
            }
            .sheet(isPresented: $showingInstructions) {
                InstructionsView()
            }
        }
    }
}

