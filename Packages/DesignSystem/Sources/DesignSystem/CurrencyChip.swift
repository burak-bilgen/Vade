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
                .foregroundColor(isSelected ? Color.vdInk900 : Color.vdInk700)
                .padding(.horizontal, Spacing.l).padding(.vertical, Spacing.s)
                .background(Capsule().fill(isSelected ? Color.vdBrass300 : Color.vdSurface))
                .overlay(Capsule().stroke(isSelected ? Color.vdBrass500 : Color.vdHairline, lineWidth: 1))
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    HStack {
        CurrencyChip(label: "TRY", isSelected: true, action: {})
        CurrencyChip(label: "USD", isSelected: false, action: {})
    }
    .padding().background(Color.vdBackground)
}
