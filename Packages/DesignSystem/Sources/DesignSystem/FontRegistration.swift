import SwiftUI
import OSLog

// MARK: - Font Registration

/// No custom font registration is needed since Vade uses system fonts
/// (SF Pro Rounded + SF Mono). This is kept for backward compatibility.
public enum FontRegistration {
    private static let logger = Logger(subsystem: "com.vade.designsystem", category: "fonts")

    /// No-op — system fonts are built into iOS.
    public static func registerAll() {
        logger.info("[FontRegistration] Using system fonts — no custom registration needed.")
    }
}
