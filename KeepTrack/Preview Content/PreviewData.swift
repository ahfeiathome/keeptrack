import CoreData
import Foundation

enum PreviewData {
    @MainActor
    static var sampleItems: [Item] {
        let context = PersistenceController.preview.container.viewContext
        let request = Item.fetchRequest()
        return (try? context.fetch(request)) ?? []
    }

    @discardableResult
    nonisolated static func populate(context: NSManagedObjectContext) -> [Item] {
        let now = Date()
        let calendar = Calendar.current

        // MARK: - Seed stores
        let target = Store(context: context)
        target.id = UUID()
        target.name = "Target"
        target.returnDays = 90
        target.warrantyPolicy = "90-day return policy on most items"
        target.receiptRequired = true
        target.createdAt = now

        let bestBuy = Store(context: context)
        bestBuy.id = UUID()
        bestBuy.name = "Best Buy"
        bestBuy.returnDays = 15
        bestBuy.warrantyPolicy = "15-day return on electronics; Geek Squad plans available"
        bestBuy.receiptRequired = true
        bestBuy.createdAt = now

        let amazon = Store(context: context)
        amazon.id = UUID()
        amazon.name = "Amazon"
        amazon.returnDays = 30
        amazon.warrantyPolicy = "30-day return policy"
        amazon.receiptRequired = false
        amazon.createdAt = now

        // MARK: - Receipt 1 (Best Buy — MacBook, expiring soon in 1 day)
        let receipt1 = Receipt(context: context)
        receipt1.id = UUID()
        receipt1.storeId = bestBuy.id!
        receipt1.purchaseDate = calendar.date(byAdding: .day, value: -14, to: now)!
        receipt1.total = 1299.99
        receipt1.createdAt = now
        receipt1.store = bestBuy

        let macbook = Item(context: context)
        macbook.id = UUID()
        macbook.receiptId = receipt1.id!
        macbook.name = "MacBook Air 13\""
        macbook.price = 1299.99
        macbook.category = "Electronics"
        macbook.warrantyMonths = 12
        macbook.returnDeadline = calendar.date(byAdding: .day, value: 1, to: now)
        macbook.warrantyDeadline = calendar.date(byAdding: .month, value: 12, to: receipt1.purchaseDate!)
        macbook.isReturned = false
        macbook.createdAt = now
        macbook.receipt = receipt1

        // MARK: - Receipt 2 (Target — headphones, expiring in 5 days)
        let receipt2 = Receipt(context: context)
        receipt2.id = UUID()
        receipt2.storeId = target.id!
        receipt2.purchaseDate = calendar.date(byAdding: .day, value: -85, to: now)!
        receipt2.total = 79.99
        receipt2.createdAt = now
        receipt2.store = target

        let headphones = Item(context: context)
        headphones.id = UUID()
        headphones.receiptId = receipt2.id!
        headphones.name = "Sony WH-1000XM5 Headphones"
        headphones.price = 79.99
        headphones.category = "Electronics"
        headphones.warrantyMonths = 12
        headphones.returnDeadline = calendar.date(byAdding: .day, value: 5, to: now)
        headphones.warrantyDeadline = calendar.date(byAdding: .month, value: 12, to: receipt2.purchaseDate!)
        headphones.isReturned = false
        headphones.createdAt = now
        headphones.receipt = receipt2

        // MARK: - Receipt 3 (Amazon — jacket, 20 days left)
        let receipt3 = Receipt(context: context)
        receipt3.id = UUID()
        receipt3.storeId = amazon.id!
        receipt3.purchaseDate = calendar.date(byAdding: .day, value: -10, to: now)!
        receipt3.total = 124.50
        receipt3.createdAt = now
        receipt3.store = amazon

        let jacket = Item(context: context)
        jacket.id = UUID()
        jacket.receiptId = receipt3.id!
        jacket.name = "North Face Fleece Jacket"
        jacket.price = 124.50
        jacket.category = "Clothing"
        jacket.returnDeadline = calendar.date(byAdding: .day, value: 20, to: now)
        jacket.isReturned = false
        jacket.createdAt = now
        jacket.receipt = receipt3

        // MARK: - Receipt 4 (Target — toy, expired)
        let receipt4 = Receipt(context: context)
        receipt4.id = UUID()
        receipt4.storeId = target.id!
        receipt4.purchaseDate = calendar.date(byAdding: .day, value: -120, to: now)!
        receipt4.total = 34.99
        receipt4.createdAt = now
        receipt4.store = target

        let toy = Item(context: context)
        toy.id = UUID()
        toy.receiptId = receipt4.id!
        toy.name = "LEGO Technic Set"
        toy.price = 34.99
        toy.category = "Toy"
        toy.returnDeadline = calendar.date(byAdding: .day, value: -30, to: now)
        toy.isReturned = false
        toy.createdAt = now
        toy.receipt = receipt4

        // MARK: - Receipt 5 (Best Buy — monitor, 14 days left)
        let receipt5 = Receipt(context: context)
        receipt5.id = UUID()
        receipt5.storeId = bestBuy.id!
        receipt5.purchaseDate = calendar.date(byAdding: .day, value: -1, to: now)!
        receipt5.total = 349.99
        receipt5.createdAt = now
        receipt5.store = bestBuy

        let monitor = Item(context: context)
        monitor.id = UUID()
        monitor.receiptId = receipt5.id!
        monitor.name = "LG 27\" 4K Monitor"
        monitor.price = 349.99
        monitor.category = "Electronics"
        monitor.warrantyMonths = 36
        monitor.returnDeadline = calendar.date(byAdding: .day, value: 14, to: now)
        monitor.warrantyDeadline = calendar.date(byAdding: .month, value: 36, to: receipt5.purchaseDate!)
        monitor.isReturned = false
        monitor.createdAt = now
        monitor.receipt = receipt5

        try? context.save()

        return [macbook, headphones, jacket, toy, monitor]
    }
}
