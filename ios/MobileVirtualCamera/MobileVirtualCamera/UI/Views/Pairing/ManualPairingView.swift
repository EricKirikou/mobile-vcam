import SwiftUI

// MARK: - Manual Pairing View
public struct ManualPairingView: View {
    @Binding var pairCode: String
    let isLoading: Bool
    let onSubmit: () -> Void

    public init(pairCode: Binding<String>, isLoading: Bool, onSubmit: @escaping () -> Void) {
        self._pairCode = pairCode
        self.isLoading = isLoading
        self.onSubmit = onSubmit
    }

    public var body: some View {
        VStack(spacing: 24) {
            Text("Enter Pairing Code")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)

            Text("Type the 6-character code displayed on your Desktop app")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Pin Entry Input
            TextField("e.g. A9B2X4", text: $pairCode)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(AppTheme.surface)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppTheme.primary, lineWidth: 1.5)
                )
                .foregroundColor(.white)
                .frame(maxWidth: 280)
                .onChange(of: pairCode) { newValue in
                    pairCode = String(newValue.prefix(8)).uppercased()
                }

            GlowingButton(
                title: "Pair Device",
                icon: "link",
                isLoading: isLoading,
                action: onSubmit
            )
            .frame(maxWidth: 280)
            .disabled(pairCode.trimmingCharacters(in: .whitespacesAndNewlines).count < 4)
        }
        .padding(24)
        .background(AppTheme.card)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }
}

