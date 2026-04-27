import XCTest
import CoreData
@testable import KeepTrack

// MARK: - BurnRateTests
// Tests for SubscriptionService.normalizeToMonthly, calculateTotalBurn, burnByCategory.
// Mirrors the logic in SubCheck's BurnRateTests but uses KeepTrack's Decimal-based
// SubscriptionService instead of the Double-based SubCheck version.

final class BurnRateTests: XCTestCase {

    // MARK: - In-memory Core Data stack

    private var container: NSPersistentContainer!
    private var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        container = NSPersistentContainer(name: "KeepTrack")
        let description = NSPersistentStoreDescription()
        description.url = URL(fileURLWithPath: "/dev/null")
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            XCTAssertNil(error, "Failed to load in-memory store: \(error!)")
        }
        context = container.viewContext
    }

    override func tearDown() {
        context = nil
        container = nil
        super.tearDown()
    }

    // MARK: - normalizeToMonthly

    func testNormalizeMonthly() {
        // Monthly → unchanged
        XCTAssertEqual(SubscriptionService.normalizeToMonthly(price: 10.0, cycle: 0), 10.0)
    }

    func testNormalizeAnnual() {
        // Annual → divide by 12
        XCTAssertEqual(SubscriptionService.normalizeToMonthly(price: 120.0, cycle: 1), 10.0)
    }

    func testNormalizeWeekly() {
        // Weekly → multiply by 4
        XCTAssertEqual(SubscriptionService.normalizeToMonthly(price: 10.0, cycle: 2), 40.0)
    }

    func testNormalizeUnknownCycle() {
        // Unknown cycle → return price unchanged
        XCTAssertEqual(SubscriptionService.normalizeToMonthly(price: 15.0, cycle: 99), 15.0)
    }

    // MARK: - calculateTotalBurn

    func testTotalBurnEmpty() {
        let burn = SubscriptionService.calculateTotalBurn(from: [])
        XCTAssertEqual(burn.monthly, 0)
        XCTAssertEqual(burn.annual, 0)
    }

    func testTotalBurnMonthlyAndAnnual() {
        // Monthly $10 + Annual $120 (= $10/mo) → $20/mo, $240/yr
        let subs = [
            makeSubscription(price: 10.0, cycle: 0, status: "active"),
            makeSubscription(price: 120.0, cycle: 1, status: "active"),
        ]
        let burn = SubscriptionService.calculateTotalBurn(from: subs)
        XCTAssertEqual(burn.monthly, 20.0)
        XCTAssertEqual(burn.annual, 240.0)
    }

    func testCancelledSubsExcluded() {
        let subs = [
            makeSubscription(price: 10.0, cycle: 0, status: "active"),
            makeSubscription(price: 5.0, cycle: 0, status: "cancelled"),
        ]
        let burn = SubscriptionService.calculateTotalBurn(from: subs)
        // Only the $10 active sub should count
        XCTAssertEqual(burn.monthly, 10.0)
    }

    func testTrialSubsIncluded() {
        // Trial subs (status == "trial") are NOT cancelled so they count
        let subs = [
            makeSubscription(price: 9.99, cycle: 0, status: "trial"),
        ]
        let burn = SubscriptionService.calculateTotalBurn(from: subs)
        XCTAssertEqual(burn.monthly, 9.99)
    }

    // MARK: - burnByCategory

    func testBurnByCategory() {
        let subs = [
            makeSubscription(price: 20.0, cycle: 0, status: "active", category: "Streaming"),
            makeSubscription(price: 10.0, cycle: 0, status: "active", category: "Streaming"),
            makeSubscription(price: 15.0, cycle: 0, status: "active", category: "Productivity"),
        ]
        let breakdown = SubscriptionService.burnByCategory(from: subs)

        // Streaming first (higher spend)
        XCTAssertEqual(breakdown[0].category, "Streaming")
        XCTAssertEqual(breakdown[0].monthly, 30.0)
        XCTAssertEqual(breakdown[0].count, 2)

        XCTAssertEqual(breakdown[1].category, "Productivity")
        XCTAssertEqual(breakdown[1].monthly, 15.0)
        XCTAssertEqual(breakdown[1].count, 1)
    }

    // MARK: - Helpers

    private func makeSubscription(
        price: Decimal,
        cycle: Int16,
        status: String,
        category: String = "Other"
    ) -> Subscription {
        let sub = Subscription(context: context)
        sub.id = UUID()
        sub.name = "Test \(UUID().uuidString.prefix(6))"
        sub.price = NSDecimalNumber(decimal: price)
        sub.billingCycle = cycle
        sub.status = status
        sub.category = category
        sub.createdAt = Date()
        return sub
    }
}
