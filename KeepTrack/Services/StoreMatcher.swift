import CoreData
import Foundation

// MARK: - Static store entry loaded from stores.json
struct StoreEntry: Decodable {
    let name: String
    let aliases: [String]
    let returnDays: Int
}

// MARK: - Store matching service
final class StoreMatcher {

    // MARK: - Catalog loaded once at startup
    static let catalog: [StoreEntry] = {
        guard
            let url = Bundle.main.url(forResource: "stores", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let entries = try? JSONDecoder().decode([StoreEntry].self, from: data)
        else { return [] }
        return entries
    }()

    // MARK: - Public API
    /// Finds or creates a Store entity matching the given name string.
    /// Uses case-insensitive partial matching against aliases in stores.json.
    static func match(name: String, context: NSManagedObjectContext) -> Store {
        let normalized = name.lowercased().trimmingCharacters(in: .whitespaces)

        // 1. Try to match against catalog
        if let entry = bestMatch(for: normalized) {
            return findOrCreate(canonicalName: entry.name, returnDays: entry.returnDays, context: context)
        }

        // 2. No catalog match — check existing Core Data stores for a fuzzy hit
        let existingRequest = Store.fetchRequest()
        let existing = (try? context.fetch(existingRequest)) ?? []
        if let hit = existing.first(where: { ($0.name ?? "").lowercased().contains(normalized) || normalized.contains(($0.name ?? "").lowercased()) }) {
            return hit
        }

        // 3. Create a brand-new store with the raw name
        return findOrCreate(canonicalName: name.trimmingCharacters(in: .whitespaces), returnDays: 30, context: context)
    }

    // MARK: - Catalog matching
    private static func bestMatch(for normalized: String) -> StoreEntry? {
        // Exact alias match first
        if let exact = catalog.first(where: { $0.aliases.contains(normalized) }) {
            return exact
        }
        // Partial alias match
        if let partial = catalog.first(where: { entry in
            entry.aliases.contains { alias in
                normalized.contains(alias) || alias.contains(normalized)
            }
        }) {
            return partial
        }
        return nil
    }

    // MARK: - Core Data find-or-create
    private static func findOrCreate(
        canonicalName: String,
        returnDays: Int,
        context: NSManagedObjectContext
    ) -> Store {
        let request = Store.fetchRequest()
        request.predicate = NSPredicate(format: "name ==[c] %@", canonicalName)
        request.fetchLimit = 1

        if let existing = try? context.fetch(request), let store = existing.first {
            return store
        }

        let store = Store(context: context)
        store.id = UUID()
        store.name = canonicalName
        store.returnDays = Int16(returnDays)
        store.receiptRequired = true
        store.createdAt = Date()
        return store
    }
}
