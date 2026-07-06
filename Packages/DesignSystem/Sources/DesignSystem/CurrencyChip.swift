import SwiftUI

public struct CurrencyChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    public init(label: String, isSelected: Bool, action: @escaping () -> Void) {
        self.label = label
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(label)
                .font(Typography.font(for: .caption)).fontWeight(.medium)
                .foregroundStyle(isSelected ? ColorTokens.textPrimary : ColorTokens.textSecondary)
                .padding(.horizontal, Spacing.l).padding(.vertical, Spacing.s)
                .background(Capsule().fill(isSelected ? ColorTokens.accentLight : ColorTokens.surface))
                .overlay(Capsule().stroke(isSelected ? ColorTokens.accent : ColorTokens.border, lineWidth: 1))
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    HStack {
        CurrencyChip(label: "TRY", isSelected: true, action: {})
        CurrencyChip(label: "USD", isSelected: false, action: {})
    }
    .padding().background(ColorTokens.background)
}
