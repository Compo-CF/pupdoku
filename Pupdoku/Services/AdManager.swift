import Foundation
import Observation
import UIKit
import GoogleMobileAds

/// Thin wrapper around Google Mobile Ads with a deliberately gentle interstitial
/// policy (the competitor's #1 complaint is ad frequency/length and surprise
/// mid-game video). Our rules:
///   - Banner: menus/Home only, never over an active board.
///   - Rewarded: strictly opt-in ("watch for a hint").
///   - Interstitial: only BETWEEN puzzles, never during one; a first-run grace
///     of `interstitialGraceWins` wins, then at most once every
///     `interstitialEveryNWins` completions AND once per 3 minutes.
///
/// DEBUG uses Google test units; Release uses the real Pupdoku units.
@MainActor
@Observable
final class AdManager: NSObject {
    static let testBannerUnitId       = "ca-app-pub-3940256099942544/2934735716"
    static let testInterstitialUnitId = "ca-app-pub-3940256099942544/4411468910"
    static let testRewardedUnitId     = "ca-app-pub-3940256099942544/1712485313"

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
    private var lastInterstitialWin: Int = 0

    // Humane pacing.
    private let interstitialMinInterval: TimeInterval = 180  // 3 min
    private let interstitialGraceWins = 5                    // no interstitials until the 5th win
    private let interstitialEveryNWins = 3                   // then at most 1 per 3 completions

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
            rewardedAd = ad; rewardedReady = true
        } catch {
            rewardedReady = false
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                await self?.loadRewarded()
            }
        }
    }

    func showRewarded(from root: UIViewController, onReward: @escaping () -> Void, onDismiss: @escaping () -> Void = {}) {
        guard let ad = rewardedAd else { onDismiss(); Task { await loadRewarded() }; return }
        rewardedReady = false
        ad.present(from: root) { onReward() }
        Task { await loadRewarded(); onDismiss() }
    }

    // MARK: - Interstitial
    func loadInterstitial() async {
        do {
            let ad = try await InterstitialAd.load(with: interstitialUnitId, request: Request())
            interstitialAd = ad; interstitialReady = true
        } catch {
            interstitialReady = false
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                guard let self else { return }
                if !self.removeAdsOwned { await self.loadInterstitial() }
            }
        }
    }

    /// Call ONLY between puzzles. Applies the grace/frequency/rate gates.
    func showInterstitialIfReady(from root: UIViewController, totalWins: Int) {
        guard !removeAdsOwned else { return }
        guard totalWins >= interstitialGraceWins else { return }
        guard totalWins - lastInterstitialWin >= interstitialEveryNWins else { return }
        if let last = lastInterstitialShownAt, Date().timeIntervalSince(last) < interstitialMinInterval { return }
        guard let ad = interstitialAd else { Task { await loadInterstitial() }; return }
        ad.present(from: root)
        lastInterstitialShownAt = Date()
        lastInterstitialWin = totalWins
        interstitialReady = false
        Task { await loadInterstitial() }
    }
}
