import XCTest
import CoreData
@testable import KeepTrack

// MARK: - WasteScoreTests
// Tests for SubscriptionService.calculateWasteScore.
// Adapted from SubCheck's WasteScoreTests; uses KeepTrack's Subscription entity.

final class WasteScoreTests: XCTestCase {

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

    // MARK: - Base score (default freq/value = 2/5)

    func testLowPriceProducesLowScore() {
        let sub = makeSubscription(price: 1.0, status: "active")
        let score = SubscriptionService.calculateWasteScore(subscription: sub)
        // $1 / (2*5) * 10 = 1.0 → score 1
        XCTAssertEqual(score, 1)
    }

    func testHighPriceProducesHigherScore() {
        let sub = makeSubscription(price: 20.0, status: "active")
        let score = SubscriptionService.calculateWasteScore(subscription: sub)
        // $20 / (2*5) * 10 = 20 → score 20
        XCTAssertEqual(score, 20)
    }

    func testScoreCappedAt100() {
        let sub = makeSubscription(price: 999.99, status: "active")
        let score = SubscriptionService.calculateWasteScore(subscription: sub)
        XCTAssertEqual(score, 100, "Score must never exceed 100")
    }

    func testScoreNotNegative() {
        let sub = makeSubscription(price: 0.0, status: "active")
        let score = SubscriptionService.calculateWasteScore(subscription: sub)
        XCTAssertGreaterThanOrEqual(score, 0, "Score must never be negative")
    }

    // MARK: - Inactivity decay

    func testInactivityDecayDoublesScore() {
        let oldDate = Calendar.current.date(byAdding: .day, value: -31, to: Date())!
        let sub = makeSubscription(price: 10.0, status: "active")
        sub.lastUsedDate = oldDate

        let score = SubscriptionService.calculateWasteScore(subscription: sub)
        // Base: $10/(2*5)*10 = 10; with 2× decay = 20
        XCTAssertEqual(score, 20, "31-day-old sub should have 2× base score")
    }

    func testRecentUsageNoDecay() {
        let sub = makeSubscription(price: 10.0, status: "active")
        sub.lastUsedDate = Date()

        let score = SubscriptionService.calculateWasteScore(subscription: sub)
        // No decay for recently used
        XCTAssertEqual(score, 10)
    }

    func testNilLastUsedActiveOldSubHasDecay() {
        // Active sub with no lastUsedDate and created > 30 days ago → 1.5× penalty
        let oldCreatedAt = Calendar.current.date(byAdding: .day, value: -31, to: Date())!
        let sub = makeSubscription(price: 10.0, status: "active")
        sub.createdAt = oldCreatedAt
        sub.lastUsedDate = nil

        let score = SubscriptionService.calculateWasteScore(subscription: sub)
        // Base 10 × 1.5 = 15
        XCTAssertEqual(score, 15, "Active sub with no usage and 31+ days since creation should get 1.5× penalty")
    }

    func testNilLastUsedNewSubNoDecay() {
        // Active sub created today, no lastUsedDate → no decay
        let sub = makeSubscription(price: 10.0, status: "active")
        sub.createdAt = Date()
        sub.lastUsedDate = nil

        let score = SubscriptionService.calculateWasteScore(subscription: sub)
        XCTAssertEqual(score, 10, "Brand-new sub should not receive inactivity penalty")
    }

    // MARK: - riskColor

    func testRiskColorLow() {
        XCTAssertEqual(SubscriptionService.riskColor(for: 0), "green")
        XCTAssertEqual(SubscriptionService.riskColor(for: 40), "green")
    }

    func testRiskColorMedium() {
        XCTAssertEqual(SubscriptionService.riskColor(for: 41), "orange")
        XCTAssertEqual(SubscriptionService.riskColor(for: 70), "orange")
    }

    func testRiskColorHigh() {
        XCTAssertEqual(SubscriptionService.riskColor(for: 71), "red")
        XCTAssertEqual(SubscriptionService.riskColor(for: 100), "red")
    }

    // MARK: - Helpers

    private func makeSubscription(price: Decimal, status: String) -> Subscription {
        let sub = Subscription(context: context)
        sub.id = UUID()
        sub.name = "Test \(UUID().uuidString.prefix(6))"
        sub.price = NSDecimalNumber(decimal: price)
        sub.billingCycle = 0 // Monthly
        sub.status = status
        sub.category = "Other"
        sub.createdAt = Date()
        return sub
    }
}
