import AVFoundation
import CoreData
import PhotosUI
import SwiftUI
import Vision

// MARK: - State machine
enum CaptureState {
    case camera
    case processing
    case review(OCRResult)
    case manual
}

// MARK: - Form model for review / manual entry
private struct ItemForm {
    var name: String = ""
    var retailer: String = ""
    var purchaseDate: Date = Date()
    var returnDeadline: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    var price: String = ""
    var total: String = ""
}

// MARK: - Main sheet
private let freeItemLimit = 10

struct CaptureSheet: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "isReturned == NO")
    )
    private var activeItems: FetchedResults<Item>

    @StateObject private var store = StoreManager.shared

    var onSave: (() -> Void)?

    @State private var state: CaptureState = .camera
    @State private var capturedImageData: Data?
    @State private var form = ItemForm()
    @State private var photosItem: PhotosPickerItem?
    @State private var errorMessage: String?
    @State private var showUpgradePrompt = false

    var body: some View {
        NavigationStack {
            Group {
                switch state {
                case .camera:
                    cameraBody
                case .processing:
                    processingBody
                case .review(let result):
                    reviewBody(result: result)
                case .manual:
                    manualBody
                }
            }
            .navigationTitle(navigationTitle)
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

    // MARK: - Camera state
    private var cameraBody: some View {
        ZStack(alignment: .bottom) {
            CameraView { data in
                capturedImageData = data
                Task { await runOCR(on: data) }
            }
            .ignoresSafeArea(edges: .top)

            VStack(spacing: 16) {
                HStack(spacing: 32) {
                    PhotosPicker(selection: $photosItem, matching: .images) {
                        Label("Library", systemImage: "photo.on.rectangle")
                            .foregroundStyle(.white)
                    }
                    .onChange(of: photosItem) { _, item in
                        guard let item else { return }
                        Task {
                            if let data = try? await item.loadTransferable(type: Data.self) {
                                capturedImageData = data
                                await runOCR(on: data)
                            }
                        }
                    }

                    Button {
                        state = .manual
                    } label: {
                        Label("Manual", systemImage: "keyboard")
                            .foregroundStyle(.white)
                    }
                }
                .padding(.bottom, 8)
            }
            .padding(.bottom, 40)
            .background(
                LinearGradient(
                    colors: [.black.opacity(0.6), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: 160)
            )
        }
    }

    // MARK: - Processing state
    private var processingBody: some View {
        VStack(spacing: 24) {
            Spacer()
            ProgressView("Reading your receipt...")
                .progressViewStyle(.circular)
                .controlSize(.large)
            if let img = capturedImageData.flatMap({ UIImage(data: $0) }) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.3)))
            }
            Spacer()
        }
        .padding()
    }

    // MARK: - Review state
    private func reviewBody(result: OCRResult) -> some View {
        Form {
            if result.isLowConfidence {
                Section {
                    Label("Low confidence — please verify fields", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }

            Section("Item") {
                TextField("Item name", text: $form.name)
                TextField("Price (optional)", text: $form.price)
                    .keyboardType(.decimalPad)
            }

            Section("Purchase") {
                TextField("Retailer", text: $form.retailer)
                DatePicker("Purchase date", selection: $form.purchaseDate, displayedComponents: .date)
                DatePicker("Return deadline", selection: $form.returnDeadline, displayedComponents: .date)
            }

            Section {
                Button("Save Item") { saveItem() }
                    .frame(maxWidth: .infinity)
                    .bold()
                    .disabled(form.name.isEmpty)

                Button("Enter Manually") { state = .manual }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.secondary)
            }

            if let err = errorMessage {
                Section {
                    Text(err).foregroundStyle(.red)
                }
            }
        }
        .onAppear { populateForm(from: result) }
    }

    // MARK: - Manual entry state
    private var manualBody: some View {
        Form {
            Section("Item") {
                TextField("Item name *", text: $form.name)
                TextField("Price (optional)", text: $form.price)
                    .keyboardType(.decimalPad)
            }

            Section("Purchase") {
                TextField("Retailer", text: $form.retailer)
                DatePicker("Purchase date", selection: $form.purchaseDate, displayedComponents: .date)
                DatePicker("Return deadline", selection: $form.returnDeadline, displayedComponents: .date)
            }

            Section {
                Button("Save Item") { saveItem() }
                    .frame(maxWidth: .infinity)
                    .bold()
                    .disabled(form.name.isEmpty)
            }

            if let err = errorMessage {
                Section { Text(err).foregroundStyle(.red) }
            }
        }
    }

    // MARK: - Navigation title
    private var navigationTitle: String {
        switch state {
        case .camera: return "Scan Receipt"
        case .processing: return "Processing"
        case .review: return "Review"
        case .manual: return "Add Item"
        }
    }

    // MARK: - OCR
    @MainActor
    private func runOCR(on data: Data) async {
        state = .processing
        let result = await OCRService.recognize(imageData: data)
        if result.isLowConfidence && result.storeName == nil && result.items.isEmpty {
            state = .manual
        } else {
            state = .review(result)
        }
    }

    // MARK: - Pre-fill form from OCR
    private func populateForm(from result: OCRResult) {
        if let storeName = result.storeName, form.retailer.isEmpty {
            form.retailer = storeName
        }
        if let date = result.purchaseDate {
            form.purchaseDate = date
            // Compute return deadline from store match
            let store = StoreMatcher.match(name: form.retailer, context: context)
            let days = Int(store.returnDays)
            form.returnDeadline = Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
        }
        if form.name.isEmpty, let first = result.items.first {
            form.name = first.name
            if let price = first.price {
                form.price = "\(price)"
            }
        }
        if let total = result.total, form.total.isEmpty {
            form.total = "\(total)"
        }
    }

    // MARK: - Save to Core Data
    private func saveItem() {
        guard !form.name.isEmpty else {
            errorMessage = "Item name is required."
            return
        }

        // Enforce 10-item limit for Free users
        if !store.isPro && activeItems.count >= freeItemLimit {
            showUpgradePrompt = true
            return
        }

        let store = StoreMatcher.match(name: form.retailer.isEmpty ? "Unknown" : form.retailer, context: context)
        store.returnDays = max(store.returnDays, 1)

        let receipt = Receipt(context: context)
        receipt.id = UUID()
        receipt.purchaseDate = form.purchaseDate
        receipt.total = NSDecimalNumber(string: form.total.isEmpty ? "0" : form.total)
        receipt.storeId = store.id!
        receipt.store = store
        receipt.createdAt = Date()
        if let imgData = capturedImageData {
            receipt.imageBlob = imgData
        }

        let item = Item(context: context)
        item.id = UUID()
        item.name = form.name
        item.price = NSDecimalNumber(string: form.price.isEmpty ? "0" : form.price)
        item.receiptId = receipt.id!
        item.receipt = receipt
        item.returnDeadline = form.returnDeadline
        item.isReturned = false
        item.createdAt = Date()

        do {
            try context.save()
            // Schedule return-deadline reminders; request permission first if needed
            Task { @MainActor in
                await NotificationService.shared.requestPermission()
                ReminderScheduler.scheduleReminders(for: item)
            }
            onSave?()
            dismiss()
        } catch {
            errorMessage = "Save failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Preview
#Preview {
    CaptureSheet()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

#Preview("Review state") {
    let mockResult = OCRResult(
        storeName: "Best Buy",
        purchaseDate: Date(),
        items: [OCRLineItem(name: "AirPods Pro", price: 249.99)],
        total: 249.99,
        rawText: "Best Buy\nAirPods Pro  249.99\nTotal  249.99",
        confidence: 0.91
    )
    CaptureSheet()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .onAppear {
            // Preview starts in review mode; use this to test the review UI
        }
}
