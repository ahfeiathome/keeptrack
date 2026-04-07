import SwiftUI

struct HomeView: View {
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Item.returnDeadline, ascending: true),
            NSSortDescriptor(keyPath: \Item.warrantyDeadline, ascending: true)
        ],
        predicate: NSPredicate(format: "isReturned == NO"),
        animation: .default
    )
    private var items: FetchedResults<Item>

    @State private var showCapture = false

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(items) { item in
                            NavigationLink {
                                Text(item.name ?? "Item")
                            } label: {
                                ItemRow(item: item)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("KeepTrack")
            .toolbar {
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

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
