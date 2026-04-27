import SwiftUI
import CoreData

/// Unified savings dashboard showing all three lanes:
/// Lane 1 returns, Lane 2 warranty claims (future), Lane 3 subscription cuts.
struct SavingsDashboardView: View {
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "isReturned == YES"),
        animation: .default
    )
    private var returnedItems: FetchedResults<Item>

    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "status == 'cancelled'"),
        animation: .default
    )
    private var cancelledSubscriptions: FetchedResults<Subscription>

    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "status != 'cancelled'"),
        animation: .default
    )
    private var activeSubscriptions: FetchedResults<Subscription>

    // MARK: - Computed

    /// Value of items successfully returned (Lane 1)
    private var returnsSaved: Decimal {
        returnedItems.reduce(Decimal(0)) { $0 + ($1.price as? Decimal ?? 0) }
    }

    /// Monthly savings from cancelled subscriptions (Lane 3)
    private var subscriptionsSaved: Decimal {
        cancelledSubscriptions.reduce(Decimal(0)) { acc, sub in
            let price = sub.price as? Decimal ?? 0
            return acc + SubscriptionService.normalizeToMonthly(price: price, cycle: sub.billingCycle)
        }
    }

    /// Potential savings if high-risk (waste score > 70) subs were cancelled
    private var subscriptionPotential: Decimal {
        activeSubscriptions
            .filter { SubscriptionService.calculateWasteScore(subscription: $0) > 70 }
            .reduce(Decimal(0)) { acc, sub in
                let price = sub.price as? Decimal ?? 0
                return acc + SubscriptionService.normalizeToMonthly(price: price, cycle: sub.billingCycle)
            }
    }

    private var totalSaved: Decimal { returnsSaved + subscriptionsSaved }

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Total Banner
                Section {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "leaf.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Saved")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            Text(totalSaved, format: .currency(code: "USD"))
                                .font(.title.bold())
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // MARK: - Lane 1: Returns
                Section {
                    HStack {
                        laneIcon(systemName: "arrow.uturn.left.circle.fill", color: .blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Returns")
                                .font(.subheadline.bold())
                            Text("\(returnedItems.count) item\(returnedItems.count == 1 ? "" : "s") returned")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(returnsSaved, format: .currency(code: "USD"))
                            .font(.subheadline.bold())
                            .foregroundStyle(.blue)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Lane 1 — Returns")
                }

                // MARK: - Lane 2: Warranties
                Section {
                    HStack {
                        laneIcon(systemName: "shield.fill", color: .orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Warranties")
                                .font(.subheadline.bold())
                            Text("Claim tracking coming soon")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("—")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Lane 2 — Warranties")
                }

                // MARK: - Lane 3: Subscriptions
                Section {
                    HStack {
                        laneIcon(systemName: "checkmark.circle.fill", color: .green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Subscriptions Cut")
                                .font(.subheadline.bold())
                            Text("\(cancelledSubscriptions.count) cancelled")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(subscriptionsSaved, format: .currency(code: "USD"))
                                .font(.subheadline.bold())
                                .foregroundStyle(.green)
                            Text("/ mo saved")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)

                    if subscriptionPotential > 0 {
                        HStack {
                            laneIcon(systemName: "exclamationmark.triangle.fill", color: .orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Potential Savings")
                                    .font(.subheadline.bold())
                                Text("Cancel \(wasteSubCount) high-risk subscription\(wasteSubCount == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(subscriptionPotential, format: .currency(code: "USD"))
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.orange)
                                Text("/ mo potential")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Lane 3 — Subscriptions")
                }
            }
            .navigationTitle("Savings Report")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Helpers

    private var wasteSubCount: Int {
        activeSubscriptions.filter { SubscriptionService.calculateWasteScore(subscription: $0) > 70 }.count
    }

    private func laneIcon(systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .foregroundStyle(color)
            .font(.title2)
            .frame(width: 32)
    }
}

#if DEBUG
#Preview {
    SavingsDashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
#endif
