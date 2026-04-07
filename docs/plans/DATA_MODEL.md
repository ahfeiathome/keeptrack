# KeepTrack — Core Data Model

**Stage:** S2 DEFINE
**Date:** 2026-04-06
**Persistence:** Core Data + NSPersistentCloudKitContainer (iCloud sync)

---

## Entity Diagram

```
Store ──────────< Receipt >────────< Item
                                      │
                                   Reminder
```

- `Store` has many `Receipt`s
- `Receipt` has many `Item`s
- `Item` has many `Reminder`s (return + warranty)

---

## Entities

### Store
Seeded at install from `stores.json`. User can add custom stores.

| Attribute | Type | Notes |
|-----------|------|-------|
| `id` | UUID | PK |
| `name` | String | e.g. "Target" |
| `returnDays` | Int16 | Default return window in days |
| `warrantyPolicy` | String? | Human-readable policy description |
| `logoURL` | String? | Remote URL for store logo image |
| `receiptRequired` | Bool | Whether receipt is required for return |
| `createdAt` | Date | |

**Relationships:**
- `receipts` → `Receipt` (to-many, cascade delete)

---

### Receipt
Represents a single purchase transaction. imageBlob stored locally; path linked to iCloud Drive.

| Attribute | Type | Notes |
|-----------|------|-------|
| `id` | UUID | PK |
| `storeId` | UUID | FK → Store.id |
| `purchaseDate` | Date | Date of purchase |
| `total` | Decimal | Total amount on receipt |
| `imageBlob` | Binary Data? | Receipt image (External Storage = YES) |
| `imagePath` | String? | iCloud Drive relative path for large images |
| `ocrText` | String? | Raw OCR output from Vision |
| `notes` | String? | User notes |
| `createdAt` | Date | |
| `archivedAt` | Date? | Set when all items are past deadline |

**Relationships:**
- `store` → `Store` (to-one)
- `items` → `Item` (to-many, cascade delete)

---

### Item
Represents a single line item within a receipt.

| Attribute | Type | Notes |
|-----------|------|-------|
| `id` | UUID | PK |
| `receiptId` | UUID | FK → Receipt.id |
| `name` | String | Product name |
| `price` | Decimal | Item price |
| `category` | String? | e.g. "Electronics", "Clothing", "Appliance" |
| `warrantyMonths` | Int16? | Manufacturer warranty in months (nil if none) |
| `returnDeadline` | Date? | Computed: purchaseDate + store.returnDays |
| `warrantyDeadline` | Date? | Computed: purchaseDate + warrantyMonths * 30 |
| `isReturned` | Bool | Marked when user completes return |
| `createdAt` | Date | |

**Relationships:**
- `receipt` → `Receipt` (to-one)
- `reminders` → `Reminder` (to-many, cascade delete)

**Computed properties (not stored):**
- `daysUntilReturn`: `returnDeadline - today`
- `daysUntilWarrantyExpiry`: `warrantyDeadline - today`
- `isExpired`: both deadlines in the past

---

### Reminder
Tracks scheduled push notifications for an item deadline.

| Attribute | Type | Notes |
|-----------|------|-------|
| `id` | UUID | PK |
| `itemId` | UUID | FK → Item.id |
| `type` | String | `"return"` or `"warranty"` |
| `triggerDate` | Date | When to fire the notification |
| `sent` | Bool | Whether notification was delivered |
| `notificationId` | String? | UNNotificationRequest identifier for cancellation |
| `createdAt` | Date | |

**Relationships:**
- `item` → `Item` (to-one)

---

## iCloud Sync Strategy

### Container
Use `NSPersistentCloudKitContainer` in place of `NSPersistentContainer`. This provides automatic CloudKit mirroring with zero additional sync code.

```swift
lazy var persistentContainer: NSPersistentCloudKitContainer = {
    let container = NSPersistentCloudKitContainer(name: "KeepTrack")
    container.loadPersistentStores { _, error in
        if let error { fatalError("Core Data load error: \(error)") }
    }
    container.viewContext.automaticallyMergesChangesFromParent = true
    container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    return container
}()
```

### Image / Binary Handling
- Small receipt thumbnails (< 1 MB): stored in Core Data `imageBlob` with External Storage enabled — Core Data manages the file on disk, CloudKit syncs it automatically.
- Full-resolution images (≥ 1 MB): saved to the app's iCloud Drive document container (`FileManager.default.url(forUbiquityContainerIdentifier:)`), path stored in `Receipt.imagePath`.

### Conflict Resolution
- **Policy:** server wins / last-write-wins (`NSMergeByPropertyObjectTrumpMergePolicy`)
- **Rationale:** receipt data is append-heavy; write conflicts are rare; LWW is the correct tradeoff for simplicity
- **UI indicator:** show "Last synced: [timestamp]" in Settings to surface any lag

---

## Migration Strategy
- Use lightweight migration (`inferMappingModelAutomatically = true`) for additive changes (new optional attributes, new entities)
- Heavyweight migration only for breaking schema changes — document in `docs/plans/MIGRATIONS.md`
- Version the `.xcdatamodeld` model for every schema change

---

## Category Enum (seed values)

```swift
enum ItemCategory: String, CaseIterable {
    case electronics = "Electronics"
    case clothing = "Clothing"
    case appliance = "Appliance"
    case furniture = "Furniture"
    case grocery = "Grocery"
    case toy = "Toy"
    case tool = "Tool"
    case sporting = "Sporting Goods"
    case beauty = "Beauty"
    case other = "Other"
}
```
