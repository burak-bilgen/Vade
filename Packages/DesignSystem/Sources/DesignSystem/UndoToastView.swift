import SwiftUI

// MARK: - Undo Toast View

/// Displays an undo bar at the bottom with auto-dismiss.
/// Used for delete operations — gives the user 5-10 seconds to undo.
public struct UndoToastView: View {
    let message: LocalizedStringKey
    let undoLabel: LocalizedStringKey
    let undoAction: () -> Void
    let onDismiss: () -> Void

    public init(
        message: LocalizedStringKey,
        undoLabel: LocalizedStringKey,
        undoAction: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.message = message
        self.undoLabel = undoLabel
        self.undoAction = undoAction
        self.onDismiss = onDismiss
    }

    @State private var dismissTask: Task<Void, Never>?

    public var body: some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: "trash")
                .foregroundStyle(ColorTokens.negative)
                .accessibilityLabel(String(localized: "accessibility.deleted"))
            Text(message)
                .font(Typography.font(for: .body))
                .foregroundStyle(ColorTokens.textPrimary)
            Spacer()
            Button(action: undoAction) {
                Text(undoLabel)
                    .font(Typography.font(for: .headline))
                    .foregroundStyle(ColorTokens.accent)
            }
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Radius.md)
                .fill(ColorTokens.surface)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
        )
        .padding(.horizontal, Spacing.l)
        .padding(.bottom, Spacing.l)
        .task {
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            onDismiss()
        }
    }
}

#Preview {
    VStack {
        Spacer()
        UndoToastView(
            message: "Deleted",
            undoLabel: "Undo",
            undoAction: {},
            onDismiss: {}
        )
    }
    .background(ColorTokens.background)
}
