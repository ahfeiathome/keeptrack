import SwiftUI

struct SubscriptionDashboardView: View {
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Subscription.renewalDate, ascending: true)],
        predicate: NSPredicate(format: "status != 'cancelled'"),
        animation: .default
    )
    private var subscriptions: FetchedResults<Subscription>

    @State private var showAddSheet = false
    @State private var selectedSubscription: Subscription?

    var burnRate: BurnRate {
        SubscriptionService.calculateTotalBurn(from: Array(subscriptions))
    }

    var categoryBreakdown: [(category: String, monthly: Decimal, count: Int)] {
        SubscriptionService.burnByCategory(from: Array(subscriptions))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Monthly Burn")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            Text(burnRate.monthly, format: .currency(code: "USD"))
                                .font(.title.bold())
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Annual")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            Text(burnRate.annual, format: .currency(code: "USD"))
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Insights")
                }

                if !categoryBreakdown.isEmpty {
                    Section {
                        ForEach(categoryBreakdown, id: \.category) { item in
                            HStack {
                                Image(systemName: categoryIcon(for: item.category))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20)
                                Text(item.category)
                                    .font(.subheadline)
                                Spacer()
                                Text("\(item.count) sub\(item.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(item.monthly, format: .currency(code: "USD"))
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.secondary)
                                Text("/ mo")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    } header: {
                        Text("By Category")
                    }
                }

                Section {
                    if subscriptions.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("No active subscriptions")
                                .font(.headline)
                            Text("Add your subscriptions to see your burn rate and waste score.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity)
                    } else {
                        ForEach(subscriptions) { sub in
                            subscriptionRow(sub)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedSubscription = sub
                                }
                        }
                    }
                } header: {
                    Text("Active Subscriptions")
                }
            }
            .navigationTitle("Subscriptions")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddSubscriptionView()
            }
            .sheet(item: $selectedSubscription) { sub in
                CancelGuideView(subscriptionName: sub.name ?? "Subscription")
            }
        }
    }

    private func subscriptionRow(_ sub: Subscription) -> some View {
        HStack(spacing: 12) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: categoryIcon(for: sub.category))
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(sub.name ?? "Subscription")
                    .font(.headline)

                HStack(spacing: 4) {
                    Text(cycleText(for: sub.billingCycle))
                    if let date = sub.renewalDate {
                        Text("•")
                        Text(relativeDate(for: date))
                            .foregroundStyle(isRenewingSoon(date) ? .red : .secondary)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text((sub.price as? Decimal ?? 0), format: .currency(code: "USD"))
                    .font(.subheadline.bold())

                let score = SubscriptionService.calculateWasteScore(subscription: sub)
                HStack(spacing: 4) {
                    Text("Risk")
                        .font(.system(size: 10, weight: .bold))
                    Text("\(score)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(riskColor(for: score).opacity(0.15))
                .foregroundStyle(riskColor(for: score))
                .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }

    private func categoryIcon(for category: String?) -> String {
        guard let category, let cat = SubscriptionCategory(rawValue: category) else {
            return "creditcard.fill"
        }
        switch cat {
        case .streaming: return "play.tv.fill"
        case .productivity: return "briefcase.fill"
        case .fitness: return "figure.run"
        case .shopping: return "cart.fill"
        case .food: return "fork.knife"
        case .news: return "newspaper.fill"
        case .other: return "creditcard.fill"
        }
    }

    private func cycleText(for cycle: Int16) -> String {
        switch cycle {
        case 0: return "Monthly"
        case 1: return "Annual"
        case 2: return "Weekly"
        default: return ""
        }
    }

    private func relativeDate(for date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: .now, to: date).day ?? 0
        if days == 0 { return "Today" }
        if days == 1 { return "Tomorrow" }
        if days < 0 { return "Expired" }
        if days < 30 { return "in \(days)d" }
        return "in \(days / 30)mo"
    }

    private func isRenewingSoon(_ date: Date) -> Bool {
        let days = Calendar.current.dateComponents([.day], from: .now, to: date).day ?? 0
        return days >= 0 && days <= 3
    }

    private func riskColor(for score: Int) -> Color {
        if score > 70 { return .red }
        if score > 40 { return .orange }
        return .green
    }
}

#Preview {
    SubscriptionDashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
