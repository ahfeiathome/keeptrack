import Foundation
import UserNotifications

enum ReminderScheduler {
    // 7-day, 3-day, and 1-day intervals
    static let intervals = [7, 3, 1]

    /// Schedule return-deadline reminders for an item.
    /// Skips intervals whose trigger date has already passed.
    static func scheduleReminders(for item: Item) {
        guard
            let itemId = item.id?.uuidString,
            let deadline = item.returnDeadline,
            let name = item.name
        else { return }

        let storeName = item.receipt?.store?.name ?? ""

        Task { @MainActor in
            let status = NotificationService.shared.authorizationStatus
            guard status == .authorized || status == .provisional else { return }

            let center = UNUserNotificationCenter.current()
            let now = Date()

            for days in intervals {
                guard
                    let triggerDate = Calendar.current.date(
                        byAdding: .day, value: -days, to: deadline
                    ),
                    triggerDate > now
                else { continue }

                let content = UNMutableNotificationContent()
                content.title = "Return deadline approaching"
                content.body = days == 1
                    ? "\(name) from \(storeName) must be returned tomorrow!"
                    : "\(name) from \(storeName) must be returned in \(days) days."
                content.sound = .default
                content.badge = 1
                content.userInfo = ["itemId": itemId]

                // Fire at 9 AM on the trigger day
                var components = Calendar.current.dateComponents(
                    [.year, .month, .day], from: triggerDate
                )
                components.hour = 9
                components.minute = 0

                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: components, repeats: false
                )
                let request = UNNotificationRequest(
                    identifier: notificationId(itemId: itemId, days: days),
                    content: content,
                    trigger: trigger
                )

                try? await center.add(request)
            }
        }
    }

    /// Cancel all pending return-deadline reminders for an item.
    static func cancelReminders(for item: Item) {
        guard let itemId = item.id?.uuidString else { return }
        let identifiers = intervals.map { notificationId(itemId: itemId, days: $0) }
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    /// Cancel everything then reschedule from scratch — call on app launch / after sync.
    static func rescheduleAll(items: [Item]) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        for item in items where !item.isReturned {
            scheduleReminders(for: item)
        }
    }

    // MARK: - Private

    private static func notificationId(itemId: String, days: Int) -> String {
        "keeptrack.return.\(itemId).\(days)d"
    }
}
