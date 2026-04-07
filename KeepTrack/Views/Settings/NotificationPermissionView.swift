import SwiftUI
import UserNotifications

struct NotificationPermissionView: View {
    @ObservedObject private var notificationService = NotificationService.shared

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Notification Access")
                    .font(.body)
                statusLabel
            }

            Spacer()

            actionButton
        }
        .task {
            await notificationService.refreshAuthorizationStatus()
        }
    }

    @ViewBuilder
    private var statusLabel: some View {
        switch notificationService.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            Text("Enabled")
                .font(.caption)
                .foregroundStyle(.green)
        case .denied:
            Text("Disabled — tap Open Settings to enable")
                .font(.caption)
                .foregroundStyle(.orange)
        case .notDetermined:
            Text("Not yet requested")
                .font(.caption)
                .foregroundStyle(.secondary)
        @unknown default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch notificationService.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .denied:
            Button("Open Settings") {
                notificationService.openSettings()
            }
            .buttonStyle(.borderless)
            .font(.callout)
            .foregroundStyle(.blue)
        case .notDetermined:
            Button("Enable") {
                Task {
                    await notificationService.requestPermission()
                }
            }
            .buttonStyle(.borderless)
            .font(.callout.bold())
            .foregroundStyle(.blue)
        @unknown default:
            EmptyView()
        }
    }
}

#Preview {
    List {
        NotificationPermissionView()
    }
}
