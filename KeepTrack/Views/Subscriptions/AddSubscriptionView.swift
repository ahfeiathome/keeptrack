import SwiftUI
import CoreData

enum SubscriptionCategory: String, CaseIterable, Identifiable {
    case streaming = "Streaming"
    case productivity = "Productivity"
    case fitness = "Fitness"
    case shopping = "Shopping"
    case food = "Food"
    case news = "News"
    case other = "Other"
    
    var id: String { rawValue }
}

struct AddSubscriptionView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var store = StoreManager.shared
    
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "isReturned == NO")
    )
    private var activeItems: FetchedResults<Item>
    
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "status != 'cancelled'")
    )
    private var activeSubscriptions: FetchedResults<Subscription>
    
    var totalActiveCount: Int {
        activeItems.count + activeSubscriptions.count
    }
    
    @State private var name: String = ""
    @State private var price: String = ""
    @State private var billingCycle: Int16 = 0 // 0: Monthly, 1: Annual, 2: Weekly
    @State private var category: SubscriptionCategory = .other
    @State private var renewalDate: Date = Date()
    @State private var trialEndDate: Date = Date()
    @State private var hasTrial: Bool = false
    @State private var cancelUrl: String = ""
    @State private var errorMessage: String?
    @State private var showUpgradePrompt = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Subscription") {
                    TextField("Name *", text: $name)
                    TextField("Price", text: $price)
                        .keyboardType(.decimalPad)
                    
                    Picker("Billing Cycle", selection: $billingCycle) {
                        Text("Monthly").tag(Int16(0))
                        Text("Annual").tag(Int16(1))
                        Text("Weekly").tag(Int16(2))
                    }
                    
                    Picker("Category", selection: $category) {
                        ForEach(SubscriptionCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                }
                
                Section("Renewal") {
                    DatePicker("Next Renewal", selection: $renewalDate, displayedComponents: .date)
                    
                    Toggle("Has Free Trial", isOn: $hasTrial)
                    if hasTrial {
                        DatePicker("Trial Ends", selection: $trialEndDate, displayedComponents: .date)
                    }
                }
                
                Section("Options (Optional)") {
                    TextField("Cancel URL / Deep Link", text: $cancelUrl)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }
                
                Section {
                    Button("Save Subscription") {
                        saveSubscription()
                    }
                    .frame(maxWidth: .infinity)
                    .bold()
                    .disabled(name.isEmpty)
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Add Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showUpgradePrompt) {
                ProUpgradePrompt()
            }
        }
    }
    
    private func saveSubscription() {
        guard !name.isEmpty else {
            errorMessage = "Name is required."
            return
        }
        
        // Enforce 10-item limit across all lanes
        if !store.isPro && totalActiveCount >= 10 {
            showUpgradePrompt = true
            return
        }
        
        let sub = Subscription(context: context)
        sub.id = UUID()
        sub.name = name
        sub.price = NSDecimalNumber(string: price.isEmpty ? "0" : price)
        sub.billingCycle = billingCycle
        sub.category = category.rawValue
        sub.renewalDate = renewalDate
        sub.trialEndDate = hasTrial ? trialEndDate : nil
        sub.status = hasTrial ? "trial" : "active"
        sub.cancelUrl = cancelUrl.isEmpty ? nil : cancelUrl
        sub.createdAt = Date()
        
        do {
            try context.save()
            
            // Schedule reminders
            let savedSub = sub
            Task { @MainActor in
                await NotificationService.shared.requestPermission()
                ReminderScheduler.scheduleReminders(for: savedSub)
            }
            
            dismiss()
        } catch {
            errorMessage = "Save failed: \(error.localizedDescription)"
        }
    }
}
