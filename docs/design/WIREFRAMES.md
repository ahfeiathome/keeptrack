# KeepTrack — ASCII Wireframes
**Stage:** S3 DESIGN | **Last updated:** 2026-04-06

---

## 1. Home (Dashboard)

```
┌─────────────────────────────────┐
│  KeepTrack              [＋]    │  ← NavigationStack title + toolbar
├─────────────────────────────────┤
│  ⚠️  2 items expire this week   │  ← Alert banner (conditional)
├─────────────────────────────────┤
│  ┌───────────────────────────┐  │
│  │ [img] Nike Air Max        │  │  ← List row
│  │       Best Buy  ●3 DAYS   │  │    countdown badge (red)
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │ [img] KitchenAid Mixer    │  │
│  │       Williams Sonoma     │  │
│  │                 ●7 DAYS   │  │    (yellow)
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │ [img] Sony Headphones     │  │
│  │       Amazon    ●21 DAYS  │  │    (green)
│  └───────────────────────────┘  │
│                                 │
│        [ Empty state art ]      │  ← shown when list is empty
│   "Tap + to add your receipt"   │
│                                 │
├─────────────────────────────────┤
│  🏠 Home  📦 Archive  ⚙️ Settings │  ← TabView
│    (2)                          │    badge count on Home
└─────────────────────────────────┘
```

**SwiftUI:** `NavigationStack` > `List` (ForEach, sorted by deadline) > `TabView`

---

## 2. Capture — Camera View

```
┌─────────────────────────────────┐
│              [✕]                │  ← dismiss sheet
│                                 │
│                                 │
│       [ CAMERA VIEWFINDER ]     │
│                                 │
│                                 │
│  ┌─────────────────────────┐   │
│  │  Point at your receipt  │   │  ← instruction overlay
│  └─────────────────────────┘   │
│                                 │
│  [📷 Library]  [◉ Capture]  [🔄]│  ← bottom controls
└─────────────────────────────────┘
```

**After capture — OCR processing:**

```
┌─────────────────────────────────┐
│         Reading receipt…        │
│           [  ◌ spinner  ]       │
│                                 │
│   [receipt thumbnail preview]   │
└─────────────────────────────────┘
```

**SwiftUI:** `UIViewControllerRepresentable` (AVCapture) + `PhotosPicker` + `ProgressView`

---

## 2b. Capture — Review & Edit Form

```
┌─────────────────────────────────┐
│  ← Back            Save Item   │  ← nav buttons
├─────────────────────────────────┤
│  [receipt image thumbnail]      │
├─────────────────────────────────┤
│  Item Name                      │
│  ┌───────────────────────────┐  │
│  │ Nike Air Max 90            │  │  ← pre-filled by OCR
│  └───────────────────────────┘  │
│  Retailer                       │
│  ┌───────────────────────────┐  │
│  │ Best Buy                   │  │
│  └───────────────────────────┘  │
│  Purchase Date                  │
│  ┌───────────────────────────┐  │
│  │ 2026-03-28          [📅]  │  │
│  └───────────────────────────┘  │
│  Return Deadline                │
│  ┌───────────────────────────┐  │
│  │ 2026-04-27          [📅]  │  │
│  └───────────────────────────┘  │
│  Warranty Expires               │
│  ┌───────────────────────────┐  │
│  │ 2027-03-28          [📅]  │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌─────────────────────────┐   │
│  │    ✓  Save Item          │   │  ← primary CTA
│  └─────────────────────────┘   │
│       Enter Manually ›          │  ← fallback
└─────────────────────────────────┘
```

**SwiftUI:** `Form` > `Section` groups > `TextField`, `DatePicker`

---

## 3. Item Detail

```
┌─────────────────────────────────┐
│  ←                   […]        │  ← back + context menu (Delete)
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────┐   │
│  │                          │   │
│  │   [ Receipt Image ]      │   │  ← tappable, zooms in sheet
│  │                          │   │
│  └─────────────────────────┘   │
│                                 │
│  Nike Air Max 90                │  ← large title
│  Best Buy                       │  ← subtitle
├─────────────────────────────────┤
│  ┌──────────────┬────────────┐  │
│  │  Return       │  Warranty  │  │  ← two cards
│  │  3 DAYS LEFT  │  1 yr 5 mo │  │
│  └──────────────┴────────────┘  │
├─────────────────────────────────┤
│  🔔 Reminders on                │  ← notification chip
├─────────────────────────────────┤
│  ┌─────────────────────────┐   │
│  │  ✓ Mark as Returned      │   │  ← primary action
│  └─────────────────────────┘   │
│  [ Edit Item ]  [ Set Reminder ]│  ← secondary actions
└─────────────────────────────────┘
```

**SwiftUI:** `ScrollView` > `VStack` > `AsyncImage` + custom card views + `Button`

---

## 4. Archive

```
┌─────────────────────────────────┐
│  Archive                        │  ← NavigationStack title
│  ┌───────────────────────────┐  │
│  │ 🔍 Search items…           │  │  ← .searchable
│  └───────────────────────────┘  │
├─────────────────────────────────┤
│  [All] [Returned] [Expired] …   │  ← filter chips (horizontal scroll)
├─────────────────────────────────┤
│  March 2026                     │  ← section header
│  ┌───────────────────────────┐  │
│  │ [img] Levi's Jeans         │  │
│  │       Gap  ● RETURNED      │  │
│  └───────────────────────────┘  │
│  February 2026                  │
│  ┌───────────────────────────┐  │
│  │ [img] Blender              │  │
│  │       Target ● EXPIRED     │  │
│  └───────────────────────────┘  │
│                                 │
│  "No items match your filter"   │  ← empty state
├─────────────────────────────────┤
│  🏠 Home  📦 Archive  ⚙️ Settings │
└─────────────────────────────────┘
```

**SwiftUI:** `List` (sections by month) + `.searchable` + horizontal `ScrollView` filter chips

---

## 5. Settings

```
┌─────────────────────────────────┐
│  Settings                       │
├─────────────────────────────────┤
│  NOTIFICATIONS                  │
│  ┌───────────────────────────┐  │
│  │ Enable Reminders   [  ●  ]│  │  ← master toggle
│  │ 7 days before      [  ●  ]│  │
│  │ 3 days before      [  ●  ]│  │
│  │ 1 day before       [  ●  ]│  │
│  │ Open System Settings    › │  │  ← Link (if denied)
│  └───────────────────────────┘  │
│  PLAN                           │
│  ┌───────────────────────────┐  │
│  │ Current Plan:    FREE      │  │
│  │ Upgrade to Pro — $2.99/mo │  │  ← primary CTA
│  │ Restore Purchases          │  │
│  └───────────────────────────┘  │
│  ICLOUD SYNC  (Pro)             │
│  ┌───────────────────────────┐  │
│  │ iCloud Sync        [ ○ ] │  │  ← gated behind Pro
│  │ Status: Off                │  │
│  └───────────────────────────┘  │
│  ABOUT                          │
│  ┌───────────────────────────┐  │
│  │ Version 1.0.0              │  │
│  │ Privacy Policy           › │  │
│  │ Rate KeepTrack           › │  │
│  └───────────────────────────┘  │
├─────────────────────────────────┤
│  🏠 Home  📦 Archive  ⚙️ Settings │
└─────────────────────────────────┘
```

**SwiftUI:** `Form` > `Section` > `Toggle`, `Button`, `Link`
