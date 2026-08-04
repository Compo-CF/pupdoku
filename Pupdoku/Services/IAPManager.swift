import Foundation
import Observation
import StoreKit

/// StoreKit 2 wrapper covering Pupdoku's in-app purchases:
/// - One non-consumable: `removeads`
/// - Two consumable hint packs: `hints_small` (+10), `hints_large` (+50)
/// - Three consumable tips: tip.small / tip.medium / tip.large
///
/// Hint packs report how many hints to credit via `hintGrant(for:)`; the caller
/// (ShopView / GameStore) applies the grant once the transaction verifies.
///
/// The tip-reminder cadence mirrors Cosmica / S-Tier Eats: never in the first
/// 14 days after install, at most once every 60 days, never after any tip, plus
/// a hard "Don't ask again" opt-out.
@MainActor
@Observable
final class IAPManager {
    // MARK: - Product IDs (must match App Store Connect)
    static let removeAdsProductId    = "com.centricfiber.pupdoku.removeads"
    static let hintsSmallProductId   = "com.centricfiber.pupdoku.hints_small"
    static let hintsLargeProductId   = "com.centricfiber.pupdoku.hints_large"

    static let tipSmallProductId     = "com.centricfiber.pupdoku.tip.small"
    static let tipMediumProductId    = "com.centricfiber.pupdoku.tip.medium"
    static let tipLargeProductId     = "com.centricfiber.pupdoku.tip.large"

    static let tipProductIds: [String] = [tipSmallProductId, tipMediumProductId, tipLargeProductId]

    static let allProductIds: [String] = [
        removeAdsProductId, hintsSmallProductId, hintsLargeProductId,
    ] + tipProductIds

    static let consumableIds: Set<String> = [
        hintsSmallProductId, hintsLargeProductId,
        tipSmallProductId, tipMediumProductId, tipLargeProductId,
    ]

    /// How many hints a purchased pack credits.
    static func hintGrant(for productId: String) -> Int {
        switch productId {
        case hintsSmallProductId: return 10
        case hintsLargeProductId: return 50
        default: return 0
        }
    }

    // MARK: - Tip reminder cadence
    private let hasEverTippedKey  = "pupdoku.iap.hasEverTipped"
    private let tipNeverAskKey    = "pupdoku.tip.neverAsk"
    private let tipLastPromptKey  = "pupdoku.tip.lastPromptAt"
    private let tipInstallDateKey = "pupdoku.tip.firstSeenAt"
    private let graceDays: Double = 14
    private let betweenPromptDays: Double = 60

    // MARK: - State
    var products: [Product] = []
    var removeAdsOwned: Bool = false
    var purchaseInFlight: Bool = false
    var didTip: Bool = false
    private(set) var hasEverTipped: Bool = false
    var lastError: String?

    /// Set by `purchase` to the hint count a just-completed pack purchase should
    /// credit. The caller reads and clears it. 0 when the last purchase wasn't a pack.
    var pendingHintGrant: Int = 0

    private var updatesTask: Task<Void, Never>?

    // MARK: - Lookups
    func product(for id: String) -> Product? { products.first { $0.id == id } }
    var removeAdsProduct: Product? { product(for: Self.removeAdsProductId) }
    var hintPackProducts: [Product] {
        products.filter { $0.id == Self.hintsSmallProductId || $0.id == Self.hintsLargeProductId }
            .sorted { $0.price < $1.price }
    }
    var tipProducts: [Product] {
        products.filter { Self.tipProductIds.contains($0.id) }.sorted { $0.price < $1.price }
    }
    func displayPrice(for productId: String) -> String? { product(for: productId)?.displayPrice }

    // MARK: - Lifecycle
    func start() async {
        if UserDefaults.standard.object(forKey: tipInstallDateKey) == nil {
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: tipInstallDateKey)
        }
        hasEverTipped = UserDefaults.standard.bool(forKey: hasEverTippedKey)
        updatesTask?.cancel()
        updatesTask = listenForTransactions()
        await loadProducts()
        await refreshEntitlements()
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: Self.allProductIds)
        } catch {
            lastError = "Couldn't load products: \(error.localizedDescription)"
        }
    }

    // MARK: - Purchases

    /// Purchases a product. Returns `true` on a verified success. For hint packs,
    /// sets `pendingHintGrant` for the caller to consume.
    @discardableResult
    func purchase(_ productId: String) async -> Bool {
        guard let product = product(for: productId) else {
            lastError = "Product unavailable: \(productId)"
            return false
        }
        purchaseInFlight = true
        defer { purchaseInFlight = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let txn) = verification else {
                    lastError = "Purchase couldn't be verified."
                    return false
                }
                if productId == Self.removeAdsProductId { removeAdsOwned = true }
                let grant = Self.hintGrant(for: productId)
                if grant > 0 { pendingHintGrant = grant }
                if Self.tipProductIds.contains(productId) { markTipped() }
                await txn.finish()
                return true
            case .userCancelled:
                return false
            case .pending:
                lastError = "Purchase pending — check back after it clears."
                return false
            @unknown default:
                return false
            }
        } catch {
            lastError = "Purchase failed: \(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func purchaseTip(_ product: Product) async -> Bool { await purchase(product.id) }

    func restore() async {
        do { try await AppStore.sync() }
        catch { lastError = "Restore failed: \(error.localizedDescription)" }
        await refreshEntitlements()
    }

    private func refreshEntitlements() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let txn) = result, txn.productID == Self.removeAdsProductId {
                owned = true
                break
            }
        }
        removeAdsOwned = owned
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await update in Transaction.updates {
                guard let self else { break }
                if case .verified(let txn) = update {
                    await self.refreshEntitlements()
                    await txn.finish()
                }
            }
        }
    }

    // MARK: - Tip reminder gating

    var tipReminderEligible: Bool {
        let d = UserDefaults.standard
        guard !d.bool(forKey: tipNeverAskKey),
              !hasEverTipped,
              !tipProducts.isEmpty,
              !purchaseInFlight
        else { return false }
        let now = Date().timeIntervalSince1970
        let firstSeen = d.double(forKey: tipInstallDateKey)
        guard firstSeen > 0, now - firstSeen >= graceDays * 86400 else { return false }
        let last = d.double(forKey: tipLastPromptKey)
        return last == 0 ? true : (now - last >= betweenPromptDays * 86400)
    }

    func recordTipPromptShown() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: tipLastPromptKey)
    }

    func stopTipReminders() {
        UserDefaults.standard.set(true, forKey: tipNeverAskKey)
    }

    private func markTipped() {
        didTip = true
        hasEverTipped = true
        UserDefaults.standard.set(true, forKey: hasEverTippedKey)
    }
}
