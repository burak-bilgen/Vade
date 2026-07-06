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
                .foregroundColor(isSelected ? Color("ink900", bundle: .module) : Color("ink700", bundle: .module))
                .padding(.horizontal, Spacing.l).padding(.vertical, Spacing.s)
                .background(Capsule().fill(isSelected ? Color("brass300", bundle: .module) : Color("surface", bundle: .module)))
                .overlay(Capsule().stroke(isSelected ? Color("brass500", bundle: .module) : Color("hairline", bundle: .module), lineWidth: 1))
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    HStack {
        CurrencyChip(label: "TRY", isSelected: true, action: {})
        CurrencyChip(label: "USD", isSelected: false, action: {})
    }
    .padding().background(Color("background", bundle: .module))
}
