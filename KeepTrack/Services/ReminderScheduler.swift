import Foundation
import UserNotifications
import CoreData

enum ReminderScheduler {
    // 7-day, 3-day, and 1-day intervals
    static let intervals = [7, 3, 1]

    // MARK: - Items (Returns/Warranties)

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
                    identifier: itemNotificationId(itemId: itemId, days: days),
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
        let identifiers = intervals.map { itemNotificationId(itemId: itemId, days: $0) }
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    // MARK: - Subscriptions

    /// Schedule trial and renewal reminders for a subscription.
    static func scheduleReminders(for subscription: Subscription) {
        guard let subId = subscription.id?.uuidString,
              let name = subscription.name else { return }
        
        let trialEndDate = subscription.trialEndDate
        let renewalDate = subscription.renewalDate
        
        Task { @MainActor in
            let status = NotificationService.shared.authorizationStatus
            guard status == .authorized || status == .provisional else { return }
            
            let center = UNUserNotificationCenter.current()
            let now = Date()
            
            // 1. Trial Expiration (if applicable)
            if let trialEnd = trialEndDate, trialEnd > now {
                // Remind 3 days and 1 day before
                for days in [3, 1] {
                    guard let triggerDate = Calendar.current.date(byAdding: .day, value: -days, to: trialEnd),
                          triggerDate > now else { continue }
                    
                    let content = UNMutableNotificationContent()
                    content.title = "Trial ending soon"
                    content.body = days == 1
                        ? "Your trial for \(name) ends tomorrow!"
                        : "Your trial for \(name) ends in \(days) days."
                    content.sound = .default
                    content.badge = 1
                    content.userInfo = ["subscriptionId": subId]
                    
                    try? await center.add(UNNotificationRequest(
                        identifier: subNotificationId(subId: subId, type: "trial", days: days),
                        content: content,
                        trigger: calendarTrigger(for: triggerDate)
                    ))
                }
            }
            
            // 2. Renewal Reminder
            if let renewal = renewalDate, renewal > now {
                // Remind 1 day before
                guard let triggerDate = Calendar.current.date(byAdding: .day, value: -1, to: renewal),
                      triggerDate > now else { return }
                
                let content = UNMutableNotificationContent()
                content.title = "Subscription renewal"
                content.body = "Your \(name) subscription renews tomorrow."
                content.sound = .default
                content.badge = 1
                content.userInfo = ["subscriptionId": subId]
                
                try? await center.add(UNNotificationRequest(
                    identifier: subNotificationId(subId: subId, type: "renewal", days: 1),
                    content: content,
                    trigger: calendarTrigger(for: triggerDate)
                ))
            }
        }
    }
    
    /// Cancel all pending reminders for a subscription.
    static func cancelReminders(for subscription: Subscription) {
        guard let subId = subscription.id?.uuidString else { return }
        // Trial reminders (3d, 1d) and renewal (1d)
        let identifiers = [
            subNotificationId(subId: subId, type: "trial", days: 3),
            subNotificationId(subId: subId, type: "trial", days: 1),
            subNotificationId(subId: subId, type: "renewal", days: 1)
        ]
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    // MARK: - Global

    /// Cancel everything then reschedule from scratch — call on app launch / after sync.
    static func rescheduleAll(items: [Item], subscriptions: [Subscription]) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        for item in items where !item.isReturned {
            scheduleReminders(for: item)
        }
        
        for sub in subscriptions where sub.status != "cancelled" {
            scheduleReminders(for: sub)
        }
    }

    // MARK: - Private

    private static func itemNotificationId(itemId: String, days: Int) -> String {
        "keeptrack.return.\(itemId).\(days)d"
    }
    
    private static func subNotificationId(subId: String, type: String, days: Int) -> String {
        "keeptrack.sub.\(type).\(subId).\(days)d"
    }
    
    private static func calendarTrigger(for date: Date) -> UNCalendarNotificationTrigger {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = 9
        components.minute = 0
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    }
}
