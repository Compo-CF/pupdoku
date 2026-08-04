import Foundation
import Observation
import UIKit
import GoogleMobileAds

/// Thin wrapper around Google Mobile Ads. All three formats are exposed:
/// - Banner: pinned under the Home screen and (optionally) below the board.
/// - Rewarded: player-initiated "watch an ad for a free hint" from the game bar
///   and the shop. Always available, even for Remove-Ads owners.
/// - Interstitial: shown occasionally after finishing a puzzle, rate-limited to
///   1 per 3 min and gated by Remove Ads.
///
/// `#if DEBUG` keeps dev builds on Google's test ad units so simulator / Xcode
/// runs never generate real impressions. TestFlight & App Store use prod IDs.
///
/// NOTE: The prod IDs below are placeholders — create the "Pupdoku" app in your
/// AdMob account, then drop in the real App ID (project.yml `GADApplicationIdentifier`)
/// and the three unit IDs here before shipping.
@MainActor
@Observable
final class AdManager: NSObject {
    // Google test IDs — safe to ship, no real impressions / no payout.
    static let testBannerUnitId       = "ca-app-pub-3940256099942544/2934735716"
    static let testInterstitialUnitId = "ca-app-pub-3940256099942544/4411468910"
    static let testRewardedUnitId     = "ca-app-pub-3940256099942544/1712485313"

    // Production AdMob ad unit IDs — Pupdoku app (App ID ...~6044441811).
    static let prodBannerUnitId       = "ca-app-pub-1927040492403163/7629966166"
    static let prodInterstitialUnitId = "ca-app-pub-1927040492403163/5501516338"
    static let prodRewardedUnitId     = "ca-app-pub-1927040492403163/6879157122"

    #if DEBUG
    var bannerUnitId       = AdManager.testBannerUnitId
    var interstitialUnitId = AdManager.testInterstitialUnitId
    var rewardedUnitId     = AdManager.testRewardedUnitId
    #else
    var bannerUnitId       = AdManager.prodBannerUnitId
    var interstitialUnitId = AdManager.prodInterstitialUnitId
    var rewardedUnitId     = AdManager.prodRewardedUnitId
    #endif

    private(set) var removeAdsOwned: Bool = false
    private(set) var rewardedReady: Bool = false
    private(set) var interstitialReady: Bool = false

    private var rewardedAd: RewardedAd?
    private var interstitialAd: InterstitialAd?
    private var lastInterstitialShownAt: Date?
    private let interstitialMinInterval: TimeInterval = 180  // 3 min

    func configure(removeAdsOwned: Bool) {
        self.removeAdsOwned = removeAdsOwned
        Task {
            await loadRewarded()
            if !removeAdsOwned { await loadInterstitial() }
        }
    }

    // MARK: - Rewarded

    func loadRewarded() async {
        do {
            let ad = try await RewardedAd.load(with: rewardedUnitId, request: Request())
            rewardedAd = ad
            rewardedReady = true
        } catch {
            rewardedReady = false
            print("[AdManager] Rewarded load failed: \(error)")
            // New AdMob accounts often return "no fill" for hours; keep retrying
            // so the "watch for a hint" button comes alive once inventory matches.
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                await self?.loadRewarded()
            }
        }
    }

    /// Present the rewarded ad. `onReward` fires on a successful reward;
    /// `onDismiss` always fires when the ad closes.
    func showRewarded(from root: UIViewController,
                      onReward: @escaping () -> Void,
                      onDismiss: @escaping () -> Void = {}) {
        guard let ad = rewardedAd else {
            onDismiss()
            Task { await loadRewarded() }
            return
        }
        rewardedReady = false
        ad.present(from: root) { onReward() }
        Task {
            await loadRewarded()
            onDismiss()
        }
    }

    // MARK: - Interstitial

    func loadInterstitial() async {
        do {
            let ad = try await InterstitialAd.load(with: interstitialUnitId, request: Request())
            interstitialAd = ad
            interstitialReady = true
        } catch {
            interstitialReady = false
            print("[AdManager] Interstitial load failed: \(error)")
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                guard let self else { return }
                if !self.removeAdsOwned { await self.loadInterstitial() }
            }
        }
    }

    func showInterstitialIfReady(from root: UIViewController) {
        guard !removeAdsOwned else { return }
        if let last = lastInterstitialShownAt, Date().timeIntervalSince(last) < interstitialMinInterval { return }
        guard let ad = interstitialAd else {
            Task { await loadInterstitial() }
            return
        }
        ad.present(from: root)
        lastInterstitialShownAt = Date()
        interstitialReady = false
        Task { await loadInterstitial() }
    }
}
