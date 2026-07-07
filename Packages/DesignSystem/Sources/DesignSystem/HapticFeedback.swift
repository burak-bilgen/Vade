import UIKit

public enum HapticFeedback {
    @MainActor
    public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    @MainActor
    public static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    @MainActor
    public static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
