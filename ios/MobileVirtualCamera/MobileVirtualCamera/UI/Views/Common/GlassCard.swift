import SwiftUI

// MARK: - Glass Card
public struct GlassCard<Content: View>: View {
    private let content: Content
    private let cornerRadius: CGFloat
    private let padding: CGFloat

    public init(cornerRadius: CGFloat = 16, padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppTheme.card.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Glowing Button
public struct GlowingButton: View {
    let title: String
    let icon: String?
    let gradient: LinearGradient
    let isLoading: Bool
    let action: () -> Void

    public init(
        title: String,
        icon: String? = nil,
        gradient: LinearGradient = AppTheme.primaryGradient,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.gradient = gradient
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .bold))
                    }
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: AppTheme.primary.opacity(0.4), radius: 10, x: 0, y: 4)
        }
        .disabled(isLoading)
    }
}

// MARK: - Status Badge
public struct StatusBadge: View {
    let isLive: Bool
    let text: String

    public init(isLive: Bool, text: String) {
        self.isLive = isLive
        self.text = text
    }

    public var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isLive ? AppTheme.liveGreen : AppTheme.warning)
                .frame(width: 8, height: 8)
                .shadow(color: (isLive ? AppTheme.liveGreen : AppTheme.warning).opacity(0.8), radius: 4)
            Text(text)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.6))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(isLive ? AppTheme.liveGreen.opacity(0.5) : AppTheme.border, lineWidth: 1)
        )
    }
}

