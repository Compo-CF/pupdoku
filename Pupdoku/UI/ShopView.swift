import SwiftUI
import StoreKit

/// The store: Bones currency, the Parade Pass subscription, Starter Pack, Event
/// Passes, cosmetics (themes), hint packs, Remove Ads, and the tip jar.
struct ShopView: View {
    @Environment(GameStore.self) private var store
    @Environment(IAPManager.self) private var iap
    @Environment(HapticsManager.self) private var haptics
    @Environment(\.dismiss) private var dismiss
    @State private var showThemes = false

    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private let privacyURL = URL(string: "https://compo-cf.github.io/pupdoku/privacy.html")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    bonesHeader
                    paradePassSection
                    section("Get Bones") { bonesTiers }
                    if !iap.removeAdsOwned && !store.subscriptionActive { starterPack }
                    section("Event Passes") { eventPasses }
                    cosmetics
                    section("Hint Packs") { hintPacks }
                    if !iap.removeAdsOwned && !store.subscriptionActive { removeAds }
                    section("Tip the Developer") { tips }
                    Button("Restore purchases") { Task { await iap.restore() } }
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Palette.inkSoft).padding(.top, 4)
                }
                .padding(20)
            }
            .pupBackground()
            .navigationTitle("Shop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
            .sheet(isPresented: $showThemes) { ThemesView() }
        }
    }

    // MARK: - Header
    private var bonesHeader: some View {
        HStack(spacing: 12) {
            Text("🦴").font(.system(size: 34))
            VStack(alignment: .leading, spacing: 2) {
                Text("\(store.bones) Bones").font(.system(size: 22, weight: .black, design: .rounded))
                Text("spend on hints, themes & passes").font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(Palette.inkSoft)
            }
            Spacer()
        }
        .foregroundStyle(Palette.ink).pupCard()
    }

    // MARK: - Parade Pass
    @ViewBuilder
    private var paradePassSection: some View {
        if store.subscriptionActive {
            HStack(spacing: 12) {
                Text("🎉").font(.system(size: 30))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Parade Pass active").font(.system(size: 17, weight: .heavy, design: .rounded))
                    Text("Ad-free + unlimited hints").font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(Palette.inkSoft)
                }
                Spacer()
            }
            .foregroundStyle(Palette.ink).pupCard()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("🎪 Parade Pass").font(.system(size: 20, weight: .black, design: .rounded))
                    Spacer()
                    Text(iap.displayPrice(for: IAPManager.paradePassMonthly).map { "\($0) / mo" } ?? "")
                        .font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(Palette.accentDeep)
                }
                perk("Play with no ads")
                perk("Unlimited hints")
                Button { buy(IAPManager.paradePassMonthly) } label: {
                    Text("Subscribe").font(.system(size: 17, weight: .heavy, design: .rounded))
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Palette.accent, in: Capsule()).foregroundStyle(.white)
                }
                .buttonStyle(.plain).disabled(iap.purchaseInFlight)
                Text("Auto-renews monthly until canceled. Payment is charged to your Apple ID at confirmation. Manage or cancel anytime in your Apple ID settings.")
                    .font(.system(size: 11, weight: .regular, design: .rounded)).foregroundStyle(Palette.inkSoft)
                HStack(spacing: 14) {
                    Link("Terms", destination: termsURL)
                    Link("Privacy", destination: privacyURL)
                }
                .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(Palette.ink).pupCard()
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Palette.accent.opacity(0.5), lineWidth: 1.5))
        }
    }

    private func perk(_ t: String) -> some View {
        Label(t, systemImage: "checkmark.circle.fill")
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(Palette.ink)
    }

    // MARK: - Bones tiers
    private var bonesTiers: some View {
        VStack(spacing: 10) {
            ForEach(iap.boneProducts, id: \.id) { p in
                row(emoji: "🦴", title: p.displayName, detail: nil, price: p.displayPrice) { buy(p.id) }
            }
            if iap.boneProducts.isEmpty { loading }
        }
    }

    // MARK: - Starter Pack
    private var starterPack: some View {
        section("Starter Pack") {
            row(emoji: "🎁", title: "Starter Pack",
                detail: "600 Bones + Remove Ads + Midnight theme",
                price: iap.displayPrice(for: IAPManager.starterPackProductId)) { buy(IAPManager.starterPackProductId) }
        }
    }

    // MARK: - Event passes
    private var eventPasses: some View {
        VStack(spacing: 10) {
            ForEach(EventPassCatalog.all) { pass in
                if store.ownsEventPass(pass.id) {
                    ownedRow(emoji: pass.emoji, title: pass.name)
                } else {
                    VStack(spacing: 8) {
                        row(emoji: pass.emoji, title: pass.name, detail: "Theme + costumes",
                            price: iap.displayPrice(for: pass.productId)) { buy(pass.productId) }
                        Button {
                            if store.buyEventPassWithBones(pass) { haptics.unlock() } else { haptics.select() }
                        } label: {
                            Text("or \(pass.bonesPrice) 🦴")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(store.bones >= pass.bonesPrice ? Palette.accentDeep : Palette.inkSoft)
                        }
                        .buttonStyle(.plain).disabled(store.bones < pass.bonesPrice)
                    }
                }
            }
        }
    }

    // MARK: - Cosmetics
    private var cosmetics: some View {
        section("Cosmetics") {
            Button { showThemes = true } label: {
                HStack(spacing: 14) {
                    Text("🎨").font(.system(size: 28))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Board Themes").font(.system(size: 16, weight: .heavy, design: .rounded))
                        Text("Unlock and switch color themes").font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(Palette.inkSoft)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(Palette.inkSoft)
                }
                .foregroundStyle(Palette.ink).pupCard()
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Hint packs / Remove Ads / Tips
    private var hintPacks: some View {
        VStack(spacing: 10) {
            ForEach(iap.hintPackProducts, id: \.id) { p in
                row(emoji: "💡", title: p.displayName, detail: "\(IAPManager.hintGrant(for: p.id)) hints", price: p.displayPrice) { buy(p.id) }
            }
            if iap.hintPackProducts.isEmpty { loading }
        }
    }

    private var removeAds: some View {
        section("Remove Ads") {
            row(emoji: "🚫", title: "Remove Ads", detail: "Hide banners and interstitials forever",
                price: iap.displayPrice(for: IAPManager.removeAdsProductId)) { buy(IAPManager.removeAdsProductId) }
        }
    }

    private var tips: some View {
        VStack(spacing: 10) {
            Text("Pupdoku is made by a tiny team. A tip is a lovely bonus and totally optional.")
                .font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(Palette.inkSoft)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(iap.tipProducts, id: \.id) { p in
                row(emoji: "☕️", title: p.displayName, detail: nil, price: p.displayPrice) { buy(p.id) }
            }
            if iap.tipProducts.isEmpty { loading }
        }
    }

    // MARK: - Building blocks
    @ViewBuilder
    private func section(_ title: String, @ViewBuilder _ content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(Palette.inkSoft)
            content()
        }
    }

    @ViewBuilder
    private func row(emoji: String, title: String, detail: String?, price: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(emoji).font(.system(size: 28))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 16, weight: .heavy, design: .rounded))
                    if let detail { Text(detail).font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(Palette.inkSoft) }
                }
                Spacer()
                Text(price ?? "…").font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Palette.accent, in: Capsule())
            }
            .foregroundStyle(Palette.ink).pupCard()
        }
        .buttonStyle(.plain).disabled(iap.purchaseInFlight || price == nil)
    }

    private func ownedRow(emoji: String, title: String) -> some View {
        HStack(spacing: 14) {
            Text(emoji).font(.system(size: 28))
            Text(title).font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundStyle(Palette.ink)
            Spacer()
            Label("Owned", systemImage: "checkmark.circle.fill").foregroundStyle(Palette.success)
                .font(.system(size: 14, weight: .bold, design: .rounded))
        }
        .pupCard()
    }

    private var loading: some View {
        HStack { ProgressView(); Text("Loading…").font(.system(size: 13, design: .rounded)).foregroundStyle(Palette.inkSoft) }
            .frame(maxWidth: .infinity).pupCard()
    }

    private func buy(_ id: String) { Task { if await iap.purchase(id) { haptics.unlock() } } }
}
