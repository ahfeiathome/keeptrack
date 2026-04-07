# KeepTrack — Notification Strategy
**Stage:** S3 DESIGN | **Last updated:** 2026-04-06

---

## Default Reminder Intervals

Three local notifications are scheduled per item **relative to the return deadline**:

| Interval | Message format |
|----------|---------------|
| 7 days before | "{Item Name}: 7 days left to return — don't miss the window" |
| 3 days before | "{Item Name}: 3 days left to return" |
| 1 day before | "{Item Name}: Last day to return — act today" |

**Warranty reminders** follow the same pattern (7 / 3 / 1 day before warranty expiry), scoped to Pro users only.

If a deadline has already passed when an item is saved, no notifications are scheduled for that item.

---

## User Configuration

Users can toggle each interval on or off in **Settings → Notifications**:

- Master toggle: disables/enables ALL notifications for the app
- Per-interval toggles: 7-day / 3-day / 1-day (each independently enabled)
- At least one interval must remain active if master is on (UI enforces this)
- Changes take effect immediately — existing pending notifications are cancelled and rescheduled

---

## Badge Count

`UNUserNotificationCenter` badge is set to the count of items whose return deadline falls **within the next 7 days** (not expired, not archived).

Badge is updated:
- On app foreground (`scenePhase == .active`)
- After any item is saved, archived, or deleted
- When notification settings change

```swift
// Pseudocode
let soonCount = items.filter { 
    $0.returnDeadline > Date.now && 
    $0.returnDeadline <= Date.now.addingTimeInterval(7 * 86400) 
}.count
UNUserNotificationCenter.current().setBadgeCount(soonCount)
```

---

## UNUserNotificationCenter Implementation Notes

### Permission Request
Request authorization on first item save (not on launch — avoid permission fatigue):

```swift
UNUserNotificationCenter.current().requestAuthorization(
    options: [.alert, .sound, .badge]
) { granted, error in
    if granted { scheduleNotifications(for: item) }
}
```

### Scheduling a Notification

```swift
func scheduleReminder(for item: KeepTrackItem, daysBeforeDeadline: Int) {
    let content = UNMutableNotificationContent()
    content.title = item.name
    content.body = "\(daysBeforeDeadline) days left to return"
    content.sound = .default

    let triggerDate = Calendar.current.date(
        byAdding: .day, value: -daysBeforeDeadline, to: item.returnDeadline
    )!
    let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: triggerDate)
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

    let id = "\(item.id.uuidString)-\(daysBeforeDeadline)d"
    let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

    UNUserNotificationCenter.current().add(request)
}
```

### Notification Identifiers

Format: `{itemUUID}-{interval}d`
Examples:
- `A1B2C3D4-...-7d` — 7-day reminder
- `A1B2C3D4-...-3d` — 3-day reminder
- `A1B2C3D4-...-1d` — 1-day reminder

This allows targeted cancellation when an item is archived or deleted:

```swift
func cancelNotifications(for item: KeepTrackItem) {
    let ids = [7, 3, 1].map { "\(item.id.uuidString)-\($0)d" }
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
}
```

### Re-scheduling After Settings Change

```swift
func reschedulAllNotifications(items: [KeepTrackItem], settings: NotificationSettings) {
    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    guard settings.masterEnabled else { return }
    for item in items where !item.isArchived {
        for interval in settings.enabledIntervals {  // [7, 3, 1] filtered by toggles
            scheduleReminder(for: item, daysBeforeDeadline: interval)
        }
    }
}
```

### Handling Permission Denied

Check status before scheduling. If denied, surface a link to System Settings:

```swift
UNUserNotificationCenter.current().getNotificationSettings { settings in
    if settings.authorizationStatus == .denied {
        // Show "Open System Settings" link in Settings screen
        // URL: UIApplication.openSettingsURLString
    }
}
```

### Delivery Time
Schedule notifications to fire at **10:00 AM local time** on the trigger day (not midnight). Set the `.hour` component to 10 when building `dateComponents`.

---

## Notification Payload Summary

| Field | Value |
|-------|-------|
| Category | `RETURN_REMINDER` |
| Sound | Default |
| Interruption level | `.timeSensitive` (iOS 15+) |
| Thread identifier | `item.id.uuidString` (groups per item in Notification Center) |
| Deep-link action | Tap opens Item Detail for that item |
