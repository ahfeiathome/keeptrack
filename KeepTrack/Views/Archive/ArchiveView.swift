import SwiftUI

struct ArchiveView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.returnDeadline, ascending: false)],
        predicate: NSPredicate(format: "isReturned == YES OR (returnDeadline != nil AND returnDeadline < %@)", Date() as CVarArg),
        animation: .default
    )
    private var archivedItems: FetchedResults<Item>

    @State private var searchText = ""

    var filteredItems: [Item] {
        guard !searchText.isEmpty else { return Array(archivedItems) }
        return archivedItems.filter { item in
            (item.name ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if archivedItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 64))
                            .foregroundStyle(.secondary)
                        Text("No Archived Items")
                            .font(.title2.bold())
                        Text("Returned or expired items appear here")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(filteredItems) { item in
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
            .navigationTitle("Archive")
            .searchable(text: $searchText, prompt: "Search items")
        }
    }
}

#Preview {
    ArchiveView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
