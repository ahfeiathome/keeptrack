import Foundation
import CoreData

struct BurnRate {
    let monthly: Decimal
    let annual: Decimal
}

enum SubscriptionService {
    
    /// Normalizes subscription price to monthly.
    /// Cycles: 0: Monthly, 1: Annual, 2: Weekly
    static func normalizeToMonthly(price: Decimal, cycle: Int16) -> Decimal {
        switch cycle {
        case 0: // Monthly
            return price
        case 1: // Annual
            return price / 12
        case 2: // Weekly
            return price * 4 // Approximation: 4 weeks in a month
        default:
            return price
        }
    }

    /// Calculates total monthly and annual burn from a list of subscriptions.
    static func calculateTotalBurn(from subscriptions: [Subscription]) -> BurnRate {
        let activeSubs = subscriptions.filter { $0.status != "cancelled" }
        let totalMonthly = activeSubs.reduce(Decimal(0)) { result, sub in
            let price = (sub.price as? Decimal) ?? 0
            return result + normalizeToMonthly(price: price, cycle: sub.billingCycle)
        }

        return BurnRate(monthly: totalMonthly, annual: totalMonthly * 12)
    }
    
    /// Calculates the waste score (risk) for a subscription.
    /// In KeepTrack, we'll simplify this to use lastUsedDate and price since we don't 
    /// currently have usageFrequency/userValue in the basic model (can add later if needed).
    /// For now, porting the logic but providing defaults for missing fields.
    static func calculateWasteScore(subscription: Subscription) -> Int {
        let price = (subscription.price as? Decimal ?? 0)
        let priceDouble = NSDecimalNumber(decimal: price).doubleValue
        
        // Defaulting freq and value for now as they aren't in KeepTrack's Subscription entity yet
        let freq = 2 // Medium frequency
        let value = 5 // Medium value
        
        // Formula: (Price / (Frequency * Value)) * 10
        let safeFreq = Double(max(1, freq))
        let safeValue = Double(max(1, value))
        let weight = safeFreq * safeValue
        var score = (priceDouble / weight) * 10.0

        // Inactivity Decay Logic: x2 penalty if last used > 30 days ago
        if let lastUsedDate = subscription.lastUsedDate {
            let daysSinceUsed = Calendar.current.dateComponents([.day], from: lastUsedDate, to: Date()).day ?? 0
            if daysSinceUsed > 30 {
                score *= 2.0
            }
        } else if subscription.status == "active" {
            // If active but never used (and not a new trial), that's high risk
            // Let's check createdAt
            if let createdAt = subscription.createdAt {
                let daysSinceCreated = Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
                if daysSinceCreated > 30 {
                    score *= 1.5
                }
            }
        }

        return Int(min(100.0, max(0.0, score)))
    }
    
    static func riskColor(for score: Int) -> String {
        if score > 70 { return "red" }
        else if score > 40 { return "orange" }
        else { return "green" }
    }

    /// Returns monthly burn grouped by category, sorted by highest spend first.
    static func burnByCategory(from subscriptions: [Subscription]) -> [(category: String, monthly: Decimal, count: Int)] {
        let activeSubs = subscriptions.filter { $0.status != "cancelled" }
        var grouped: [String: (monthly: Decimal, count: Int)] = [:]
        for sub in activeSubs {
            let cat = sub.category ?? "Other"
            let price = (sub.price as? Decimal) ?? 0
            let monthly = normalizeToMonthly(price: price, cycle: sub.billingCycle)
            let existing = grouped[cat] ?? (monthly: 0, count: 0)
            grouped[cat] = (monthly: existing.monthly + monthly, count: existing.count + 1)
        }
        return grouped
            .map { (category: $0.key, monthly: $0.value.monthly, count: $0.value.count) }
            .sorted { $0.monthly > $1.monthly }
    }
}
