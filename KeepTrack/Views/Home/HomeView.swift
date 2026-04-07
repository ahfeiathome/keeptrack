import SwiftUI

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
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
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

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
