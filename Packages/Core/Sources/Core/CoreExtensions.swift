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

    var isEffectivelyZero: Bool { rounded() == 0 }
    var absoluteValue: Decimal { magnitude }

    func formatted(using locale: Locale = .current) -> String {
        // Check cache under lock - formatting inside the lock ensures
        // the cached formatter is never used concurrently by two threads.
        var result: String?
        Self.formatterQueue.sync {
            if let formatter = Self._formatterCache[locale] {
                result = formatter.string(from: self as NSDecimalNumber)
            }
        }
        if let result { return result }

        // Miss: create new formatter, format, then store with barrier.
        let newFormatter = NumberFormatter()
        newFormatter.locale = locale
        newFormatter.numberStyle = .decimal
        newFormatter.minimumFractionDigits = 2
        newFormatter.maximumFractionDigits = 2
        let formatted = newFormatter.string(from: self as NSDecimalNumber) ?? "\(self)"

        Self.formatterQueue.async(flags: .barrier) {
            Self._formatterCache[locale] = newFormatter
        }
        return formatted
    }

    nonisolated(unsafe) private static var _formatterCache: [Locale: NumberFormatter] = [:]
    private static let formatterQueue = DispatchQueue(label: "com.vade.formatterCache", attributes: .concurrent)

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
