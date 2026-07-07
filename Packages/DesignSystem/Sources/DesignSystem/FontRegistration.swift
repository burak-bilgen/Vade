import SwiftUI
import CoreText
import OSLog

// MARK: - Font Registration

/// Registers custom fonts (Plus Jakarta Sans, JetBrains Mono) with the CoreText
/// font manager so they are available via `Font.custom(_:size:)` everywhere.
///
/// Call `FontRegistration.registerAll()` once at app launch, typically from
/// the `@main` App struct's `init()` or a `.task` modifier.
public enum FontRegistration {
    private static let logger = Logger(subsystem: "com.vade.designsystem", category: "fonts")

    /// All custom font file names (without extension) in the Fonts resource directory.
    private static let fontNames: [String] = [
        "PlusJakartaSans-Light",
        "PlusJakartaSans-Regular",
        "PlusJakartaSans-Medium",
        "PlusJakartaSans-SemiBold",
        "PlusJakartaSans-Bold",
        "JetBrainsMono-Regular",
        "JetBrainsMono-Medium",
        "JetBrainsMono-SemiBold",
        "JetBrainsMono-Bold",
    ]

    /// Call once at app launch. Safe to call multiple times — subsequent calls
    /// are no-ops because already-registered fonts are skipped by CoreText.
    public static func registerAll() {
        for name in fontNames {
            guard let fontURL = Bundle.module.url(
                forResource: name,
                withExtension: "ttf",
                subdirectory: "Fonts"
            ) else {
                logger.warning("[FontRegistration] Missing font file: \(name).ttf")
                continue
            }
            var error: Unmanaged<CFError>?
            guard CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) else {
                if let err = error?.takeRetainedValue() as? NSError, err.code != 110 {
                    logger.warning("[FontRegistration] Failed to register \(name): \(err.localizedDescription)")
                }
                continue
            }
            logger.info("[FontRegistration] Registered \(name)")
        }
    }
}
