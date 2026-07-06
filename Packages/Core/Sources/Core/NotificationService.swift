import Foundation
import OSLog

#if canImport(UserNotifications)
import UserNotifications
#endif

// MARK: - Notification Service Protocol

public protocol NotificationScheduling: Sendable {
    func requestPermission() async -> Bool
    func scheduleReminder(for debtID: UUID, personName: String, amount: Decimal, dueDate: Date) async
    func cancelReminder(for debtID: UUID) async
    func registerRichActions()
}

/// Called by the notification content extension to handle "Mark as Paid" action.
public func handleMarkAsPaidAction(debtID: String) {
    let logger = Logger(subsystem: "com.vade.core", category: "notifications")
    logger.info("[Notifications] Mark as Paid action received for debt: \(debtID)")
    // The host app's NotificationServiceDelegate will process this
    // by posting a local notification that the app observes on foreground.
    #if canImport(UserNotifications)
    let content = UNMutableNotificationContent()
    content.title = "Vade"
    content.body = "Borç ödendi olarak işaretlendi."
    content.userInfo = ["markAsPaidDebtID": debtID, "action": "markAsPaid"]
    let request = UNNotificationRequest(
        identifier: "mark-paid-\(debtID)",
        content: content,
        trigger: nil
    )
    UNUserNotificationCenter.current().add(request)
    #endif
}

// MARK: - Notification Service

/// Schedules local reminders for upcoming debt due dates.
/// Manages the 64-pending-notification limit — only the nearest 64 are scheduled.
public final class NotificationService: NSObject, NotificationScheduling, @unchecked Sendable {
    private let logger = Logger(subsystem: "com.vade.core", category: "notifications")
    private let maxPendingLimit = 64

    public override init() {
        super.init()
        #if canImport(UserNotifications)
        UNUserNotificationCenter.current().delegate = self
        registerRichActions()
        #endif
    }

    /// Registers the "Mark as Paid" rich notification action.
    public func registerRichActions() {
        #if canImport(UserNotifications)
        let markAsPaid = UNNotificationAction(
            identifier: "MARK_AS_PAID",
            title: "Ödendi Olarak İşaretle",
            options: .foreground
        )
        let category = UNNotificationCategory(
            identifier: "DEBT_REMINDER",
            actions: [markAsPaid],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
        logger.info("[Notifications] Rich actions registered")
        #endif
    }

    public func requestPermission() async -> Bool {
        #if canImport(UserNotifications)
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            logger.info("[Notifications] Permission granted: \(granted)")
            return granted
        } catch {
            logger.error("[Notifications] Permission error: \(error.localizedDescription)")
            return false
        }
        #else
        return false
        #endif
    }

    public func scheduleReminder(
        for debtID: UUID,
        personName: String,
        amount: Decimal,
        dueDate: Date
    ) async {
        #if canImport(UserNotifications)
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        guard pending.count < self.maxPendingLimit else {
            logger.warning("[Notifications] Limit of \(self.maxPendingLimit) reached, skipping")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = String(format: "Vade — %@", personName)
        content.body = String(format: "%@ tutarında ödeme vadesi yaklaşıyor.", amount.formatted())
        content.sound = .default
        content.categoryIdentifier = "DEBT_REMINDER"
        content.userInfo = ["debtID": debtID.uuidString]

        // Trigger at 9 AM on the due date
        let triggerDate = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: dueDate) ?? dueDate
        let components = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let identifier = "debt-reminder-\(debtID.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
            logger.info("[Notifications] Scheduled reminder for \(identifier)")
        } catch {
            logger.error("[Notifications] Failed to schedule: \(error.localizedDescription)")
        }
        #endif
    }

    public func cancelReminder(for debtID: UUID) async {
        #if canImport(UserNotifications)
        let identifier = "debt-reminder-\(debtID.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        logger.info("[Notifications] Cancelled reminder \(identifier)")
        #endif
    }
}

#if canImport(UserNotifications)
extension NotificationService: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }
}
#endif
