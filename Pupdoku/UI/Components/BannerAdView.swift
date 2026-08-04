import SwiftUI
import GoogleMobileAds

/// SwiftUI bridge for AdMob's banner.
struct BannerAdView: UIViewRepresentable {
    let unitId: String

    func makeUIView(context: Context) -> BannerView {
        let view = BannerView(adSize: AdSizeBanner)
        view.adUnitID = unitId
        view.rootViewController = UIApplication.topViewController()
        view.load(Request())
        return view
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        if uiView.rootViewController == nil {
            uiView.rootViewController = UIApplication.topViewController()
        }
    }
}

/// Drop-in banner slot that hides itself for Remove-Ads owners.
struct BannerAdSlot: View {
    @Environment(AdManager.self) var ads

    var body: some View {
        if ads.removeAdsOwned {
            EmptyView()
        } else {
            BannerAdView(unitId: ads.bannerUnitId)
                .frame(height: 50)
        }
    }
}
