import SwiftUI

struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("remind7Days") private var remind7Days = true
    @AppStorage("remind3Days") private var remind3Days = true
    @AppStorage("remind1Day") private var remind1Day = true
    @AppStorage("badgeCountEnabled") private var badgeCountEnabled = true

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
                        Text("Free")
                            .foregroundStyle(.secondary)
                    }
                    Button("Upgrade to Pro — $2.99/mo") {
                        // StoreKit flow — S6
                    }
                    .foregroundStyle(.blue)
                    Button("Restore Purchases") {
                        // StoreKit restore — S6
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
                        // StoreKit review request — S6
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
