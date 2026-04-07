# KeepTrack — User Flow Diagrams
**Stage:** S3 DESIGN | **Last updated:** 2026-04-06

---

## Happy Path: Launch → Capture → OCR → Save → Reminder → Return

```
[App Launch]
     │
     ▼
[Home Screen]
  • List of active items sorted by deadline
  • Badge shows count expiring within 7 days
     │
     │  Tap [+]
     ▼
[Capture Sheet — Camera View]
  • Full-screen camera viewfinder
  • Instruction overlay: "Point at your receipt"
     │
     │  Tap shutter / hold to capture
     ▼
[OCR Processing]
  • Spinner: "Reading your receipt…"
  • Vision framework extracts text
  • Parser maps fields: name, retailer, date, return window, warranty
     │
     │  OCR succeeds (confidence > threshold)
     ▼
[Review & Edit Form]
  • Pre-filled fields from OCR
  • User reviews, corrects any errors
  • Taps "Save Item"
     │
     ▼
[Item Saved to Core Data / CloudKit]
  • Notification scheduled: 7d / 3d / 1d before return deadline
  • Home list refreshes, new item appears at top (soonest deadline)
     │
     │  [Time passes — push notification fires]
     ▼
[Push Notification]
  • "Nike Air Max: 3 days left to return"
  • Tap notification → deep link to Item Detail
     │
     ▼
[Item Detail]
  • Countdown card shows "3 DAYS LEFT"
  • User taps "Mark as Returned"
     │
     ▼
[Confirmation Alert]
  • "Mark Nike Air Max as returned? You won't get further reminders."
  • [Confirm] [Cancel]
     │
     │  Tap Confirm
     ▼
[Item Archived]
  • Item moves to Archive with badge "RETURNED"
  • All pending notifications for item cancelled
  • Home list refreshes (item removed)
     │
     ▼
[Archive]
  • Item visible under "Returned" filter
  • Read-only detail available
```

---

## Edge Case 1: Manual Entry (skipping camera)

```
[Capture Sheet — Camera View]
     │
     │  Tap "Enter Manually" link
     ▼
[Review & Edit Form — Empty]
  • All fields blank
  • User types: name, retailer, purchase date, return deadline, warranty
  • Taps "Save Item"
     │
     ▼
[Item Saved]  →  (same as happy path from this point)
```

---

## Edge Case 2: OCR Failure

```
[OCR Processing]
     │
     │  Confidence below threshold OR no text detected
     ▼
[OCR Failure Screen]
  • Message: "Couldn't read receipt — try again or enter manually"
  • [Try Again] — returns to camera view
  • [Enter Manually] — opens empty Review & Edit Form
     │
     │  Tap "Enter Manually"
     ▼
[Review & Edit Form — Empty]
  → same as Edge Case 1
```

---

## Edge Case 3: Notification Permission Denied

```
[First time "Save Item" is tapped]
     │
     │  App calls UNUserNotificationCenter.requestAuthorization
     ▼
[System Permission Dialog]
  • "KeepTrack would like to send you notifications"
     │
     │  User taps "Don't Allow"
     ▼
[Item Saved — No Notifications Scheduled]
  • Item appears in Home list normally
  • No reminders will fire
     │
     │  User opens Settings
     ▼
[Settings — Notifications Section]
  • "Enable Reminders" toggle shows as OFF (greyed)
  • "Open System Settings ›" link visible
     │
     │  Tap "Open System Settings ›"
     ▼
[iOS Settings → KeepTrack → Notifications]
  • User enables notifications manually
     │
     │  User returns to KeepTrack
     ▼
[Settings — Notifications Section]
  • Toggle now active
  • App re-schedules notifications for all active items with pending deadlines
```

---

## Edge Case 4: Photo Library Import (no camera)

```
[Capture Sheet — Camera View]
     │
     │  Tap [📷 Library] button
     ▼
[PhotosPicker Sheet]
  • User selects receipt photo from library
     │
     ▼
[OCR Processing]
  → same as happy path from this point
```

---

## Edge Case 5: iCloud Sync Conflict (Pro)

```
[App Launch on second device]
     │
     │  CloudKit fetches remote data
     ▼
[Conflict Detected]
  • Same item modified on two devices
  • CloudKit last-write-wins strategy applied automatically
  • No user-facing conflict UI (silent resolution)
     │
     ▼
[Home Screen]
  • Reflects merged/latest state
```
