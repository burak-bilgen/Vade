import Foundation
import OSLog

// MARK: - Decimal Helpers

public extension Decimal {
    func rounded(scale: Int = 2, mode: NSDecimalNumber.RoundingMode = .plain) -> Decimal {
        var source = self
        var result = Decimal.zero
        NSDecimalRound(&result, &source, scale, mode)
        return result
    }

    func formatted(using locale: Locale = .current) -> String {
        Self.cachedFormatter(for: locale).string(from: self as NSDecimalNumber) ?? "\(self)"
    }

    nonisolated(unsafe) private static var formatterCache: [Locale: NumberFormatter] = [:]
    private static let formatterLock = NSLock()

    private static func cachedFormatter(for locale: Locale) -> NumberFormatter {
        formatterLock.lock()
        defer { formatterLock.unlock() }
        if let cached = formatterCache[locale] {
            return cached
        }
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatterCache[locale] = formatter
        return formatter
    }

    var isEffectivelyZero: Bool { rounded() == 0 }
    var absoluteValue: Decimal { magnitude }
}

// MARK: - Date Helpers

public extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }

    func daysBetween(_ other: Date) -> Int {
        Calendar.current.dateComponents([.day], from: startOfDay, to: other.startOfDay).day ?? 0
    }
}

// MARK: - String Helpers

public extension String {
    var firstCharacter: String {
        guard let first else { return "" }
        return String(first)
    }
}

// MARK: - Bundle Helpers

public extension Bundle {
    var releaseVersionNumber: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

// MARK: - OSLog wrapper

public enum AppLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.vade"

    public static let general = Logger(subsystem: subsystem, category: "general")
    public static let data = Logger(subsystem: subsystem, category: "data")
    public static let networking = Logger(subsystem: subsystem, category: "networking")
    public static let ui = Logger(subsystem: subsystem, category: "ui")
}
