import UIKit

public enum HapticFeedback {
    public static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    public static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    public static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
