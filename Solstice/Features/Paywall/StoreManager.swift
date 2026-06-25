import StoreKit
import Observation

// MARK: - StoreManager
//
// StoreKit 2 wrapper for Solstice+ (premium). It owns three products —
// a monthly and an annual auto-renewable subscription plus a one-time
// "Lifetime" non-consumable — and exposes a single `isPremium` flag the
// rest of the app gates on.
//
// No server is involved: entitlements are verified on-device against the
// App Store's signed transactions, which keeps the privacy promise intact.
// For local testing, the products come from Solstice.storekit (configured on
// the Run scheme). For the App Store, the same product IDs are created in
// App Store Connect — the code does not change.

@MainActor
@Observable
final class StoreManager {

    // Product identifiers — must match Solstice.storekit and App Store Connect.
    static let monthlyID = "app.solstice.ios.plus.monthly"
    static let annualID = "app.solstice.ios.plus.annual"
    static let lifetimeID = "app.solstice.ios.plus.lifetime"
    static let allProductIDs: [String] = [monthlyID, annualID, lifetimeID]

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    /// Products keyed off the App Store, sorted for display (annual, lifetime, monthly).
    private(set) var products: [Product] = []
    /// Product IDs the user currently owns / is subscribed to.
    private(set) var purchasedProductIDs: Set<String> = []
    /// The single flag the app gates premium features on.
    private(set) var isPremium: Bool = false
    private(set) var loadState: LoadState = .idle

    /// True while a purchase or restore is in flight (drives button spinners).
    var isPurchasing: Bool = false
    /// User-visible error from the last purchase/restore attempt.
    var purchaseError: String?

    private var transactionListener: Task<Void, Never>?

    init() {
        // Begin listening for transactions (renewals, refunds, Ask-to-Buy approvals,
        // purchases made on another device) before doing anything else. The manager
        // lives for the whole app lifetime, so the task is never explicitly cancelled.
        transactionListener = listenForTransactions()
    }

    // MARK: - Display helpers

    var monthly: Product? { products.first { $0.id == Self.monthlyID } }
    var annual: Product? { products.first { $0.id == Self.annualID } }
    var lifetime: Product? { products.first { $0.id == Self.lifetimeID } }

    /// Approximate per-month savings of annual vs. 12× monthly, e.g. "Save 50%".
    var annualSavingsText: String? {
        guard let annual, let monthly else { return nil }
        let yearlyAtMonthly = (monthly.price as NSDecimalNumber).doubleValue * 12
        let annualPrice = (annual.price as NSDecimalNumber).doubleValue
        guard yearlyAtMonthly > 0 else { return nil }
        let saved = (yearlyAtMonthly - annualPrice) / yearlyAtMonthly
        let percent = Int((saved * 100).rounded())
        guard percent > 0 else { return nil }
        return "Save \(percent)%"
    }

    // MARK: - Loading

    func loadProducts() async {
        guard loadState != .loading else { return }
        // Entitlements are independent of the product catalog — refresh them first so
        // an owner is never gated off premium just because the catalog failed to load
        // (e.g. offline at launch).
        await refreshEntitlements()
        loadState = .loading
        do {
            let fetched = try await Product.products(for: Self.allProductIDs)
            products = fetched.sorted { lhs, rhs in
                order(for: lhs.id) < order(for: rhs.id)
            }
            loadState = .loaded
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    private func order(for id: String) -> Int {
        switch id {
        case Self.annualID: return 0
        case Self.lifetimeID: return 1
        case Self.monthlyID: return 2
        default: return 3
        }
    }

    // MARK: - Purchase

    /// Returns true if the purchase completed and unlocked premium.
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        purchaseError = nil
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
                return isPremium
            case .userCancelled:
                return false
            case .pending:
                // e.g. Ask to Buy — the listener will pick it up once approved.
                return false
            @unknown default:
                return false
            }
        } catch {
            purchaseError = error.localizedDescription
            return false
        }
    }

    // MARK: - Restore

    func restore() async {
        purchaseError = nil
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if !isPremium {
                purchaseError = "No previous purchases were found on this Apple Account."
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Entitlements

    /// Recomputes `isPremium` from the App Store's current entitlements.
    func refreshEntitlements() async {
        var owned: Set<String> = []
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if transaction.revocationDate == nil {
                owned.insert(transaction.productID)
            }
        }
        purchasedProductIDs = owned
        isPremium = !owned.isDisjoint(with: Set(Self.allProductIDs))
    }

    // MARK: - Transaction listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { continue }
                if let transaction = try? self.checkVerified(update) {
                    await transaction.finish()
                    await self.refreshEntitlements()
                }
            }
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}
