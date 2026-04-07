import StoreKit
import SwiftUI

struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("remind7Days") private var remind7Days = true
    @AppStorage("remind3Days") private var remind3Days = true
    @AppStorage("remind1Day") private var remind1Day = true
    @AppStorage("badgeCountEnabled") private var badgeCountEnabled = true

    @StateObject private var store = StoreManager.shared

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Notification Access
                Section("Notification Access") {
                    NotificationPermissionView()
                }

                // MARK: - Reminder Intervals
                Section("Reminder Intervals") {
                    Toggle("Enable Reminders", isOn: $notificationsEnabled)

                    if notificationsEnabled {
                        Toggle("7 days before", isOn: $remind7Days)
                        Toggle("3 days before", isOn: $remind3Days)
                        Toggle("1 day before", isOn: $remind1Day)
                    }

                    Toggle("Badge count on app icon", isOn: $badgeCountEnabled)
                }

                // MARK: - Pro Tier
                Section("KeepTrack Pro") {
                    HStack {
                        Text("Current Plan")
                        Spacer()
                        if store.isPro {
                            Label("Pro", systemImage: "star.fill")
                                .foregroundStyle(.yellow)
                                .fontWeight(.semibold)
                        } else {
                            Text("Free")
                                .foregroundStyle(.secondary)
                        }
                    }

                    if !store.isPro {
                        Button {
                            Task { await store.purchase() }
                        } label: {
                            HStack {
                                if store.purchaseState == .purchasing {
                                    ProgressView()
                                        .controlSize(.small)
                                        .padding(.trailing, 4)
                                }
                                Text(store.proProduct.map { "Upgrade to Pro — \($0.displayPrice)" }
                                     ?? "Upgrade to Pro — $2.99")
                            }
                        }
                        .disabled(store.purchaseState == .purchasing || store.purchaseState == .restoring)

                        Button {
                            Task { await store.restorePurchases() }
                        } label: {
                            HStack {
                                if store.purchaseState == .restoring {
                                    ProgressView()
                                        .controlSize(.small)
                                        .padding(.trailing, 4)
                                }
                                Text("Restore Purchases")
                            }
                        }
                        .disabled(store.purchaseState == .purchasing || store.purchaseState == .restoring)
                    }

                    if store.purchaseState == .pending {
                        Label("Awaiting approval (Ask to Buy)", systemImage: "clock")
                            .foregroundStyle(.orange)
                            .font(.footnote)
                    }
                }

                // MARK: - iCloud Sync
                Section("iCloud Sync") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Label("On", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                // MARK: - About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                    Link("Privacy Policy", destination: URL(string: "https://bigclaw.ai/privacy")!)
                    Button("Rate KeepTrack") {
                        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                            SKStoreReviewController.requestReview(in: scene)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Purchase Error", isPresented: Binding(
                get: { store.purchaseError != nil },
                set: { if !$0 { store.purchaseError = nil } }
            )) {
                Button("OK") { store.purchaseError = nil }
            } message: {
                Text(store.purchaseError?.errorDescription ?? "")
            }
        }
    }
}

// MARK: - Preview

#Preview("Free user") {
    SettingsView()
}

#Preview("Pro user") {
    let view = SettingsView()
    // Simulate Pro state via UserDefaults for preview
    UserDefaults.standard.set(true, forKey: "keeptrack_isPro_cached")
    return view
}
