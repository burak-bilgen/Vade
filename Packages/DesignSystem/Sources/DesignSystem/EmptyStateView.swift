import SwiftUI

public struct EmptyStateView: View {
    let title: String
    let subtitle: String

    public init(title: String, subtitle: String) {
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(spacing: Spacing.l) {
            ledgerIcon
                .foregroundStyle(ColorTokens.accentLight)
                .frame(width: 80, height: 80)
            VStack(spacing: Spacing.s) {
                Text(title).font(Typography.font(for: .title2))
                    .foregroundStyle(ColorTokens.textSecondary).multilineTextAlignment(.center)
                    .minimumScaleFactor(0.85).fixedSize(horizontal: false, vertical: true)
                Text(subtitle).font(Typography.font(for: .body))
                    .foregroundStyle(ColorTokens.textTertiary).multilineTextAlignment(.center)
                    .minimumScaleFactor(0.85).fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Spacing.xxl)
    }

    private var ledgerIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .stroke(ColorTokens.textTertiary, lineWidth: 1.5).frame(width: 60, height: 70)
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0)); p.addLine(to: CGPoint(x: 0, y: 70))
            }
            .stroke(ColorTokens.textTertiary, lineWidth: 1.5).frame(width: 60, height: 70).offset(x: -30)
            VStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 2).fill(ColorTokens.textTertiary.opacity(0.4))
                        .frame(width: 30, height: 2)
                }
            }.offset(x: 8)
        }
    }
}

#Preview {
    EmptyStateView(title: "Henüz kimseyle bir hesabın yok",
                   subtitle: "İlk kişini ekleyerek başla.")
        .background(ColorTokens.background)
}
