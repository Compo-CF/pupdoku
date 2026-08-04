import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Privacy Policy").font(.system(size: 24, weight: .black, design: .rounded))
                Text("Last updated: \(Self.lastUpdated)")
                    .font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(Palette.inkSoft)

                para("Pupdoku is designed to respect your privacy. We do not collect names, email addresses, or contact information.")
                head("Game Progress")
                para("Your progress, statistics, and settings are stored on your device and — if you are signed in to iCloud — synced privately through Apple's CloudKit to your other devices. This data is tied to your Apple ID and is not readable by us.")
                head("Advertising")
                para("Pupdoku shows ads through Google AdMob. With your permission (via the App Tracking Transparency prompt), AdMob may use your device's advertising identifier to show more relevant ads. You can decline, and you can remove ads entirely with the Remove Ads purchase. See Google's policies for details on their data practices.")
                head("Game Center")
                para("If you use Game Center, leaderboard scores and achievements are handled by Apple under Apple's privacy policy.")
                head("Purchases")
                para("In-app purchases are processed by Apple. We never see your payment details.")
                head("Children")
                para("Pupdoku is family-friendly. We do not knowingly collect personal information from children.")
                head("Contact")
                para("Questions? Reach out at the support address listed on the App Store product page.")
            }
            .padding(20)
        }
        .pupBackground()
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }

    static let lastUpdated = "August 2026"

    private func head(_ t: String) -> some View {
        Text(t).font(.system(size: 17, weight: .heavy, design: .rounded)).foregroundStyle(Palette.ink).padding(.top, 4)
    }
    private func para(_ t: String) -> some View {
        Text(t).font(.system(size: 15, weight: .regular, design: .rounded)).foregroundStyle(Palette.ink.opacity(0.85))
    }
}
