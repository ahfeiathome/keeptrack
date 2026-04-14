import CoreData
import SwiftUI
import UIKit
import UserNotifications

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Request notification permission on first launch
        Task { @MainActor in
            await NotificationService.shared.requestPermission()
        }
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Clear badge when user opens the app
        UNUserNotificationCenter.current().setBadgeCount(0)
        // Refresh permission status in case user changed it in Settings
        Task { @MainActor in
            await NotificationService.shared.refreshAuthorizationStatus()
        }
    }
}

// MARK: - App

@main
struct KeepTrackApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    rescheduleAllReminders()
                }
        }
    }

    /// Reschedule all pending notifications from current Core Data state.
    /// Handles cases where items were added/deleted while the app was closed.
    private func rescheduleAllReminders() {
        let context = persistenceController.container.viewContext
        
        let itemRequest = Item.fetchRequest()
        itemRequest.predicate = NSPredicate(format: "isReturned == NO")
        let items = (try? context.fetch(itemRequest)) ?? []
        
        let subRequest = Subscription.fetchRequest()
        subRequest.predicate = NSPredicate(format: "status != 'cancelled'")
        let subs = (try? context.fetch(subRequest)) ?? []
        
        ReminderScheduler.rescheduleAll(items: items, subscriptions: subs)
    }
}
