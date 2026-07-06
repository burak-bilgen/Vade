import SwiftUI

// MARK: - Undo Toast View

/// Displays an undo bar at the bottom with auto-dismiss.
/// Used for delete operations — gives the user 5-10 seconds to undo.
public struct UndoToastView: View {
    let message: String
    let undoLabel: String
    let undoAction: () -> Void
    let onDismiss: () -> Void

    public init(
        message: String,
        undoLabel: String,
        undoAction: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.message = message
        self.undoLabel = undoLabel
        self.undoAction = undoAction
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: "trash")
                .foregroundColor(Color("negative600"))
            Text(message)
                .font(Typography.font(for: .body))
                .foregroundColor(Color("ink900"))
            Spacer()
            Button(action: undoAction) {
                Text(undoLabel)
                    .font(Typography.font(for: .headline))
                    .foregroundColor(Color("brass500"))
            }
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Radius.md)
                .fill(Color("surface"))
                .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
        )
        .padding(.horizontal, Spacing.l)
        .padding(.bottom, Spacing.l)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                onDismiss()
            }
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
    .background(Color("background"))
}
