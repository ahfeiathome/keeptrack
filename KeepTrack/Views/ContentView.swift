import SwiftUI

struct ContentView: View {
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "returnDeadline != nil AND isReturned == NO"),
        animation: .default
    )
    private var expiringItems: FetchedResults<Item>

    var badgeCount: Int {
        let sevenDaysFromNow = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return expiringItems.filter { item in
            guard let deadline = item.returnDeadline else { return false }
            return deadline <= sevenDaysFromNow
        }.count
    }

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .badge(badgeCount > 0 ? badgeCount : 0)

            ArchiveView()
                .tabItem {
                    Label("Archive", systemImage: "archivebox.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
