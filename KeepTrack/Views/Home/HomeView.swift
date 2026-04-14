import SwiftUI

private let freeItemLimit = 10

struct HomeView: View {
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Item.returnDeadline, ascending: true),
            NSSortDescriptor(keyPath: \Item.warrantyDeadline, ascending: true)
        ],
        predicate: NSPredicate(format: "isReturned == NO"),
        animation: .default
    )
    private var items: FetchedResults<Item>

    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "status != 'cancelled'"),
        animation: .default
    )
    private var subscriptions: FetchedResults<Subscription>

    @StateObject private var store = StoreManager.shared
    @State private var showCapture = false

    private var totalSavings: Decimal {
        let itemsSum = items.reduce(Decimal(0)) { $0 + ($1.price as? Decimal ?? 0) }
        let highRiskSubs = subscriptions.filter { sub in SubscriptionService.calculateWasteScore(subscription: sub) > 70 }
        let subsSum = highRiskSubs.reduce(Decimal(0)) { $0 + ($1.price as? Decimal ?? 0) }
        return itemsSum + subsSum
    }

    private var subscriptionBurnRate: BurnRate {
        SubscriptionService.calculateTotalBurn(from: Array(subscriptions))
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty && subscriptions.isEmpty {
                    emptyState
                } else {
                    List {
                        if totalSavings > 0 {
                            Section {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Potential Savings")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.secondary)
                                            .textCase(.uppercase)
                                        Text(totalSavings, format: .currency(code: "USD"))
                                            .font(.title2.bold())
                                            .foregroundStyle(.green)
                                    }
                                    Spacer()
                                    Image(systemName: "leaf.fill")
                                        .font(.title)
                                        .foregroundStyle(.green)
                                }
                                .padding(.vertical, 8)
                            }
                        }

                        if !items.isEmpty {
                            Section("Returns & Warranties") {
                                ForEach(items) { item in
                                    NavigationLink {
                                        Text(item.name ?? "Item")
                                    } label: {
                                        ItemRow(item: item)
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            markReturned(item)
                                        } label: {
                                            Label("Returned", systemImage: "arrow.uturn.left")
                                        }
                                        .tint(.green)
                                    }
                                }
                                .onDelete(perform: deleteItems)
                            }
                        }

                        if !subscriptions.isEmpty {
                            Section(header: Text("Subscriptions")) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Monthly Burn")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .textCase(.uppercase)
                                        Text(subscriptionBurnRate.monthly, format: .currency(code: "USD"))
                                            .font(.title3.bold())
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                                ForEach(Array(subscriptions.prefix(3)), id: \.id) { sub in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(sub.name ?? "Subscription")
                                                .font(.subheadline)
                                            Text(relativeDate(for: sub.renewalDate ?? Date()))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text((sub.price as? Decimal ?? 0), format: .currency(code: "USD"))
                                            .font(.subheadline.bold())
                                    }
                                }
                                if subscriptions.count > 3 {
                                    Text("+ \(subscriptions.count - 3) more")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("KeepTrack")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if store.isPro {
                        Label("Pro", systemImage: "star.fill")
                            .foregroundStyle(.yellow)
                            .fontWeight(.semibold)
                            .font(.subheadline)
                    } else {
                        let count = items.count + subscriptions.count
                        Text("\(count)/\(freeItemLimit) items")
                            .font(.subheadline)
                            .foregroundStyle(count >= freeItemLimit ? .red : .secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCapture = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showCapture) {
                CaptureSheet {
                    showCapture = false
                }
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
            }
        }
    }

    // MARK: - Actions

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = items[index]
            ReminderScheduler.cancelReminders(for: item)
            context.delete(item)
        }
        try? context.save()
    }

    private func markReturned(_ item: Item) {
        ReminderScheduler.cancelReminders(for: item)
        item.isReturned = true
        try? context.save()
    }

    private func relativeDate(for date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: .now, to: date).day ?? 0
        if days == 0 { return "Renews today" }
        if days == 1 { return "Renews tomorrow" }
        if days < 0 { return "Expired" }
        return "Renews in \(days) days"
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "shippingbox")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("No Active Items")
                .font(.title2.bold())
            Text("Tap + to add your first receipt")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#if DEBUG
#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
#endif
