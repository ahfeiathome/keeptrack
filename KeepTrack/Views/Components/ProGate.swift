import SwiftUI

// MARK: - ProGate view modifier
// Shows an upgrade prompt sheet when the Free item limit is reached.

struct ProGateModifier: ViewModifier {
    let isPresented: Bool
    @StateObject private var store = StoreManager.shared

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: .constant(isPresented && !store.isPro)) {
                ProUpgradePrompt()
            }
    }
}

extension View {
    /// Presents the Pro upgrade prompt when `limitReached` is true and the user is on Free tier.
    func proGate(limitReached: Bool) -> some View {
        modifier(ProGateModifier(isPresented: limitReached))
    }
}

// MARK: - Upgrade prompt sheet

struct ProUpgradePrompt: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = StoreManager.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.yellow)

                Text("Upgrade to KeepTrack Pro")
                    .font(.title2.bold())

                VStack(alignment: .leading, spacing: 12) {
                    featureRow(icon: "infinity", text: "Unlimited items")
                    featureRow(icon: "bell.badge", text: "Custom reminder intervals")
                    featureRow(icon: "square.and.arrow.up", text: "CSV & PDF export")
                }
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

                Button {
                    Task { await store.purchase() }
                } label: {
                    HStack {
                        if store.purchaseState == .purchasing {
                            ProgressView().controlSize(.small).padding(.trailing, 4)
                        }
                        Text(store.proProduct.map { "Upgrade — \($0.displayPrice)/mo" }
                             ?? "Upgrade — $2.99/mo")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(store.purchaseState == .purchasing)

                Button("Restore Purchases") {
                    Task { await store.restorePurchases() }
                }
                .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("Go Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Not Now") { dismiss() }
                }
            }
            .onChange(of: store.isPro) { _, isPro in
                if isPro { dismiss() }
            }
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            Text(text)
        }
    }
}

#Preview {
    ProUpgradePrompt()
}
