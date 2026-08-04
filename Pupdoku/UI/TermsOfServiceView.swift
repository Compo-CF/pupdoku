import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Terms of Service").font(.system(size: 24, weight: .black, design: .rounded))
                Text("Last updated: \(PrivacyPolicyView.lastUpdated)")
                    .font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(Palette.inkSoft)

                para("By playing Pupdoku, you agree to these terms.")
                head("The Game")
                para("Pupdoku is provided for your personal entertainment. We work to keep it running smoothly but provide it \"as is,\" without warranties of any kind.")
                head("Purchases")
                para("In-app purchases (Remove Ads, hint packs, and tips) are handled by Apple and are subject to Apple's terms. Consumable purchases such as hints and tips are non-refundable except where required by law. Remove Ads is a one-time purchase restorable on your Apple ID.")
                head("Fair Play")
                para("Please don't attempt to tamper with, reverse engineer, or disrupt the game or its services.")
                head("Changes")
                para("We may update the game and these terms over time. Continued play after an update means you accept the current terms.")
                head("Contact")
                para("Questions? Reach out at the support address on the App Store product page.")
            }
            .padding(20)
        }
        .pupBackground()
        .navigationTitle("Terms")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func head(_ t: String) -> some View {
        Text(t).font(.system(size: 17, weight: .heavy, design: .rounded)).foregroundStyle(Palette.ink).padding(.top, 4)
    }
    private func para(_ t: String) -> some View {
        Text(t).font(.system(size: 15, weight: .regular, design: .rounded)).foregroundStyle(Palette.ink.opacity(0.85))
    }
}
