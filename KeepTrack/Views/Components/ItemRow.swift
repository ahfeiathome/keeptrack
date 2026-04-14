import SwiftUI

struct ItemRow: View {
    let item: Item

    // MARK: - Countdown badge logic
    private var daysUntilDeadline: Int? {
        guard let deadline = item.returnDeadline else { return nil }
        let days = Calendar.current.dateComponents([.day], from: .now, to: deadline).day ?? 0
        return days
    }

    private var badgeColor: Color {
        guard let days = daysUntilDeadline else { return .gray }
        if days < 0 { return .gray }
        if days < 3 { return .red }
        if days < 7 { return .yellow }
        return .green
    }

    private var badgeText: String {
        guard let days = daysUntilDeadline else { return "No deadline" }
        if days < 0 { return "Expired" }
        if days == 0 { return "Today" }
        if days == 1 { return "1 day left" }
        return "\(days) days left"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
                .frame(width: 52, height: 52)
                .overlay {
                    Image(systemName: "bag.fill")
                        .foregroundStyle(.secondary)
                }

            // Item info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name ?? "Unknown Item")
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                if let receipt = item.receipt, let store = receipt.store {
                    Text(store.name ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Countdown badge
            Text(badgeText)
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(badgeColor.opacity(0.15))
                .foregroundStyle(badgeColor)
                .clipShape(Capsule())
        }
        .padding(.vertical, 2)
    }
}

#if DEBUG
#Preview {
    List {
        ItemRow(item: PreviewData.sampleItems[0])
        ItemRow(item: PreviewData.sampleItems[1])
        ItemRow(item: PreviewData.sampleItems[2])
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
#endif
