import Foundation
import Observation
import StoreKit

/// StoreKit 2 wrapper for Pupdoku v3.0 (mirrors Critter Conga):
/// - Non-consumables: removeads, starterpack, eventpass.spooky2026, eventpass.winter2026
/// - Consumables: bones.80/500/1200/2800, hints_small/large, tip.small/medium/large
/// - Auto-renewable subscription: paradepass.monthly (ad-free + unlimited hints)
///
/// Grants the economy must apply are surfaced as pending* values the caller consumes
/// (GameStore via PupdokuApp.onChange). Entitlements (removeAdsOwned,
/// subscriptionActive, owned event passes) are recomputed from
/// Transaction.currentEntitlements on launch, purchase, and restore.
@MainActor
@Observable
final class IAPManager {
    private static let p = "com.centricfiber.pupdoku."

    static let removeAdsProductId  = p + "removeads"
    static let hintsSmallProductId = p + "hints_small"
    static let hintsLargeProductId = p + "hints_large"
    static let tipSmallProductId   = p + "tip.small"
    static let tipMediumProductId  = p + "tip.medium"
    static let tipLargeProductId   = p + "tip.large"
    static let tipProductIds = [tipSmallProductId, tipMediumProductId, tipLargeProductId]

    static let bones80  = p + "bones.80"
    static let bones500 = p + "bones.500"
    static let bones1200 = p + "bones.1200"
    static let bones2800 = p + "bones.2800"
    static let boneProductIds = [bones80, bones500, bones1200, bones2800]

    static let starterPackProductId = p + "starterpack"
    static let eventSpookyProductId = p + "eventpass.spooky2026"
    static let eventWinterProductId = p + "eventpass.winter2026"
    static let eventPassProductIds = [eventSpookyProductId, eventWinterProductId]
    static let paradePassMonthly    = p + "paradepass.monthly"

    static let allProductIds: [String] =
        [removeAdsProductId, hintsSmallProductId, hintsLargeProductId,
         starterPackProductId, paradePassMonthly]
        + boneProductIds + eventPassProductIds + tipProductIds

    static let consumableIds: Set<String> = Set(boneProductIds + [hintsSmallProductId, hintsLargeProductId] + tipProductIds)

    static func hintGrant(for id: String) -> Int {
        id == hintsSmallProductId ? 10 : (id == hintsLargeProductId ? 50 : 0)
    }
    static func bonesGrant(for id: String) -> Int {
        switch id {
        case bones80: return 80
        case bones500: return 500
        case bones1200: return 1200
        case bones2800: return 2800
        default: return 0
        }
    }

    // MARK: - State
    var products: [Product] = []
    var removeAdsOwned = false
    var subscriptionActive = false
    var restoredEventPasses: Set<String> = []
    var purchaseInFlight = false
    var lastError: String?

    var pendingHintGrant = 0
    var pendingBonesGrant = 0
    var pendingStarterPack = false
    var pendingEventPassUnlock: String?

    private let hasEverTippedKey  = "pupdoku.iap.hasEverTipped"
    private let tipNeverAskKey    = "pupdoku.tip.neverAsk"
    private let tipLastPromptKey  = "pupdoku.tip.lastPromptAt"
    private let tipInstallDateKey = "pupdoku.tip.firstSeenAt"
    private let graceDays: Double = 14
    private let betweenPromptDays: Double = 60
    private(set) var hasEverTipped = false
    var didTip = false

    private var updatesTask: Task<Void, Never>?

    // MARK: - Lookups
    func product(for id: String) -> Product? { products.first { $0.id == id } }
    func displayPrice(for id: String) -> String? { product(for: id)?.displayPrice }
    var removeAdsProduct: Product? { product(for: Self.removeAdsProductId) }
    var paradePassProduct: Product? { product(for: Self.paradePassMonthly) }
    var boneProducts: [Product] { Self.boneProductIds.compactMap { product(for: $0) } }
    var hintPackProducts: [Product] { [Self.hintsSmallProductId, Self.hintsLargeProductId].compactMap { product(for: $0) } }
    var tipProducts: [Product] { products.filter { Self.tipProductIds.contains($0.id) }.sorted { $0.price < $1.price } }

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
        do { products = try await Product.products(for: Self.allProductIds) }
        catch { lastError = "Could not load products: \(error.localizedDescription)" }
    }

    // MARK: - Purchase
    @discardableResult
    func purchase(_ productId: String) async -> Bool {
        guard let product = product(for: productId) else { lastError = "Product unavailable: \(productId)"; return false }
        purchaseInFlight = true
        defer { purchaseInFlight = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let txn) = verification else { lastError = "Purchase could not be verified."; return false }
                applyPurchase(productId)
                await txn.finish()
                await refreshEntitlements()
                return true
            case .userCancelled: return false
            case .pending: lastError = "Purchase pending — check back after it clears."; return false
            @unknown default: return false
            }
        } catch { lastError = "Purchase failed: \(error.localizedDescription)"; return false }
    }

    private func applyPurchase(_ productId: String) {
        switch productId {
        case Self.removeAdsProductId: removeAdsOwned = true
        case Self.starterPackProductId: pendingStarterPack = true; removeAdsOwned = true
        case Self.eventSpookyProductId, Self.eventWinterProductId:
            pendingEventPassUnlock = productId; restoredEventPasses.insert(productId)
        default:
            let h = Self.hintGrant(for: productId); if h > 0 { pendingHintGrant += h }
            let b = Self.bonesGrant(for: productId); if b > 0 { pendingBonesGrant += b }
            if Self.tipProductIds.contains(productId) { markTipped() }
        }
    }

    @discardableResult
    func purchaseTip(_ product: Product) async -> Bool { await purchase(product.id) }

    func restore() async {
        do { try await AppStore.sync() } catch { lastError = "Restore failed: \(error.localizedDescription)" }
        await refreshEntitlements()
    }

    private func refreshEntitlements() async {
        var ads = false, sub = false
        var passes: Set<String> = []
        for await result in Transaction.currentEntitlements {
            guard case .verified(let txn) = result else { continue }
            switch txn.productID {
            case Self.removeAdsProductId, Self.starterPackProductId: ads = true
            case Self.paradePassMonthly: sub = true
            case Self.eventSpookyProductId, Self.eventWinterProductId: passes.insert(txn.productID)
            default: break
            }
        }
        removeAdsOwned = ads
        subscriptionActive = sub
        restoredEventPasses = passes
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await update in Transaction.updates {
                guard let self else { break }
                if case .verified(let txn) = update { await self.refreshEntitlements(); await txn.finish() }
            }
        }
    }

    // MARK: - Tip gating
    var tipReminderEligible: Bool {
        let d = UserDefaults.standard
        guard !d.bool(forKey: tipNeverAskKey), !hasEverTipped, !tipProducts.isEmpty, !purchaseInFlight else { return false }
        let now = Date().timeIntervalSince1970
        let firstSeen = d.double(forKey: tipInstallDateKey)
        guard firstSeen > 0, now - firstSeen >= graceDays * 86400 else { return false }
        let last = d.double(forKey: tipLastPromptKey)
        return last == 0 ? true : (now - last >= betweenPromptDays * 86400)
    }
    func recordTipPromptShown() { UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: tipLastPromptKey) }
    func stopTipReminders() { UserDefaults.standard.set(true, forKey: tipNeverAskKey) }
    private func markTipped() {
        didTip = true; hasEverTipped = true
        UserDefaults.standard.set(true, forKey: hasEverTippedKey)
    }
}
