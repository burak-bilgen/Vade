import SwiftUI
import OSLog

/// Registers custom fonts from the DesignSystem bundle at app launch.
public enum FontRegistrar {
    private static let logger = Logger(subsystem: "com.vade.designsystem", category: "fonts")

    public static func registerFonts() {
        let fontNames = [
            "PlusJakartaSans-Regular",
            "PlusJakartaSans-Medium",
            "PlusJakartaSans-SemiBold",
            "PlusJakartaSans-Bold",
            "JetBrainsMono-Regular",
            "JetBrainsMono-Medium",
        ]
        for name in fontNames {
            guard let url = Bundle.module.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts")
            else { continue }
            var error: Unmanaged<CFError>?
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
            if let error {
                logger.error("[FontRegistrar] Failed to register \(name): \(error.takeRetainedValue().localizedDescription)")
            }
        }
    }
}
