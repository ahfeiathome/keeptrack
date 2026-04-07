import Foundation
import StoreKit

// MARK: - Pro product identifier
private let proProductID = "com.bigclaw.keeptrack.pro"
private let proStatusKey = "keeptrack_isPro_cached"

// MARK: - StoreManager
@MainActor
final class StoreManager: ObservableObject {

    static let shared = StoreManager()

    @Published var isPro: Bool = UserDefaults.standard.bool(forKey: proStatusKey)
    @Published var proProduct: Product?
    @Published var purchaseError: StoreError?
    @Published var purchaseState: PurchaseState = .idle

    private var updateListenerTask: Task<Void, Never>?

    private init() {
        updateListenerTask = listenForTransactions()
        Task { await fetchProducts() }
        Task { await verifyEntitlements() }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Fetch products

    func fetchProducts() async {
        do {
            let products = try await Product.products(for: [proProductID])
            proProduct = products.first
        } catch {
            // Products unavailable (e.g. no network) — silently ignore; cached isPro still valid
        }
    }

    // MARK: - Purchase

    func purchase() async {
        guard let product = proProduct else {
            purchaseError = .productNotAvailable
            return
        }
        purchaseState = .purchasing

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                setPro(true)
                purchaseState = .idle

            case .pending:
                // Ask to Buy — waiting for parent approval
                purchaseState = .pending

            case .userCancelled:
                purchaseState = .idle

            @unknown default:
                purchaseState = .idle
            }
        } catch StoreKitError.notEntitled {
            purchaseError = .notEntitled
            purchaseState = .idle
        } catch StoreKitError.networkError {
            purchaseError = .networkUnavailable
            purchaseState = .idle
        } catch {
            purchaseError = .unknown(error.localizedDescription)
            purchaseState = .idle
        }
    }

    // MARK: - Restore purchases

    func restorePurchases() async {
        purchaseState = .restoring
        do {
            try await AppStore.sync()
            await verifyEntitlements()
        } catch {
            purchaseError = .restoreFailed(error.localizedDescription)
        }
        purchaseState = .idle
    }

    // MARK: - Background transaction listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                do {
                    let transaction = try self.checkVerified(result)
                    if transaction.productID == proProductID {
                        if transaction.revocationDate != nil {
                            // Refund detected — revoke Pro
                            await MainActor.run { self.setPro(false) }
                        } else {
                            await MainActor.run { self.setPro(true) }
                        }
                        await transaction.finish()
                    }
                } catch {
                    // Verification failed — ignore unverified transaction
                }
            }
        }
    }

    // MARK: - Verify entitlements on launch

    func verifyEntitlements() async {
        var hasPro = false
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.productID == proProductID && transaction.revocationDate == nil {
                    hasPro = true
                }
            } catch {
                // Skip unverified
            }
        }
        setPro(hasPro)
    }

    // MARK: - Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let value):
            return value
        }
    }

    private func setPro(_ value: Bool) {
        isPro = value
        UserDefaults.standard.set(value, forKey: proStatusKey)
        purchaseState = .idle
    }
}

// MARK: - Supporting types

enum PurchaseState: Equatable {
    case idle
    case purchasing
    case restoring
    case pending
}

enum StoreError: LocalizedError {
    case productNotAvailable
    case verificationFailed
    case notEntitled
    case networkUnavailable
    case restoreFailed(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .productNotAvailable:
            return "Product is not available right now. Please try again later."
        case .verificationFailed:
            return "Purchase verification failed. Please contact support."
        case .notEntitled:
            return "You are not entitled to this purchase."
        case .networkUnavailable:
            return "No network connection. Please check your internet and try again."
        case .restoreFailed(let msg):
            return "Restore failed: \(msg)"
        case .unknown(let msg):
            return "An error occurred: \(msg)"
        }
    }
}
