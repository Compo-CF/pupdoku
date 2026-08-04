import SwiftUI
import StoreKit

/// In-app purchases: Remove Ads, hint packs, and the optional tip jar.
struct ShopView: View {
    @Environment(GameStore.self) private var store
    @Environment(IAPManager.self) private var iap
    @Environment(HapticsManager.self) private var haptics
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    hintBalanceCard

                    if !iap.removeAdsOwned {
                        productCard(
                            title: "Remove Ads", emoji: "🚫",
                            detail: "Hide banners and skip interstitials forever.",
                            price: iap.displayPrice(for: IAPManager.removeAdsProductId),
                            action: { await buy(IAPManager.removeAdsProductId) }
                        )
                    }

                    section("Hint Packs") {
                        ForEach(iap.hintPackProducts, id: \.id) { product in
                            productCard(
                                title: product.displayName, emoji: "💡",
                                detail: "\(IAPManager.hintGrant(for: product.id)) hints",
                                price: product.displayPrice,
                                action: { await buy(product.id) }
                            )
                        }
                        if iap.hintPackProducts.isEmpty { loadingRow }
                    }

                    section("Tip the Developer") {
                        Text("Pupdoku is made by a tiny team. A tip is a lovely bonus — and totally optional. 🐾")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Palette.inkSoft)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ForEach(iap.tipProducts, id: \.id) { product in
                            productCard(
                                title: product.displayName, emoji: "☕️",
                                detail: nil, price: product.displayPrice,
                                action: { await buy(product.id) }
                            )
                        }
                        if iap.tipProducts.isEmpty { loadingRow }
                    }

                    Button("Restore purchases") { Task { await iap.restore() } }
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Palette.inkSoft)
                        .padding(.top, 4)
                }
                .padding(20)
            }
            .pupBackground()
            .navigationTitle("Shop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }

    private var hintBalanceCard: some View {
        HStack(spacing: 12) {
            Text("💡").font(.system(size: 34))
            VStack(alignment: .leading, spacing: 2) {
                Text("\(store.hintBalance) hints").font(.system(size: 22, weight: .black, design: .rounded))
                Text("available to spend").font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(Palette.inkSoft)
            }
            Spacer()
        }
        .foregroundStyle(Palette.ink)
        .pupCard()
    }

    @ViewBuilder
    private func section(_ title: String, @ViewBuilder _ content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(Palette.inkSoft)
            content()
        }
    }

    @ViewBuilder
    private func productCard(title: String, emoji: String, detail: String?, price: String?,
                             action: @escaping () async -> Void) -> some View {
        Button { Task { await action() } } label: {
            HStack(spacing: 14) {
                Text(emoji).font(.system(size: 28))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 16, weight: .heavy, design: .rounded))
                    if let detail {
                        Text(detail).font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(Palette.inkSoft)
                    }
                }
                Spacer()
                Text(price ?? "…")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Palette.accent, in: Capsule())
            }
            .foregroundStyle(Palette.ink)
            .pupCard()
        }
        .buttonStyle(.plain)
        .disabled(iap.purchaseInFlight || price == nil)
    }

    private var loadingRow: some View {
        HStack { ProgressView(); Text("Loading…").font(.system(size: 13, design: .rounded)).foregroundStyle(Palette.inkSoft) }
            .frame(maxWidth: .infinity).pupCard()
    }

    private func buy(_ productId: String) async {
        let ok = await iap.purchase(productId)
        if ok { haptics.unlock() }
    }
}
