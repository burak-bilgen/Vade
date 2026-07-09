import Foundation
import OSLog

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Screen Protection Protocol

public protocol ScreenProtecting: Sendable {
    func enableBlurOnBackground()
    func disableBlurOnBackground()
    func blockScreenshots(_ shouldBlock: Bool)
}

// MARK: - Screen Protector

/// Handles app background blur (privacy) and screenshot blocking for sensitive screens.
public final class ScreenProtector: ScreenProtecting, @unchecked Sendable {
    private let logger = Logger(subsystem: "com.vade.core", category: "screenProtect")

    public init() {}

    public func enableBlurOnBackground() {
        #if canImport(UIKit)
        Task { @MainActor in
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else { return }
            let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
            blur.tag = 9991
            blur.frame = window.bounds
            blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            window.addSubview(blur)
            logger.info("[ScreenProtector] Blur enabled")
        }
        #endif
    }

    public func disableBlurOnBackground() {
        #if canImport(UIKit)
        Task { @MainActor in
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else { return }
            window.subviews.filter { $0.tag == 9991 }.forEach { $0.removeFromSuperview() }
        }
        #endif
    }

    public func blockScreenshots(_ shouldBlock: Bool) {
        #if canImport(UIKit)
        Task { @MainActor in
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else { return }
            if shouldBlock {
                // UITextField with isSecureTextEntry prevents screenshot/recording
                let field = UITextField()
                field.isSecureTextEntry = true
                field.tag = 9992
                window.addSubview(field)
                // Keep it offscreen - it just needs to be in the view hierarchy
                field.center = CGPoint(x: -100, y: -100)
                logger.info("[ScreenProtector] Screenshot blocking enabled")
            } else {
                window.subviews.filter { $0.tag == 9992 }.forEach { $0.removeFromSuperview() }
            }
        }
        #endif
    }
}
