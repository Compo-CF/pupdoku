import SwiftUI
import StoreKit

/// The gentle, opt-out tip prompt. Cadence is governed by `IAPManager`
/// (never in the first 14 days, at most every 60, never after tipping).
struct TipReminderView: View {
    @Environment(IAPManager.self) private var iap
    @Environment(HapticsManager.self) private var haptics
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Text("🐶💛").font(.system(size: 64))
            Text("Enjoying Pupdoku?")
                .font(.system(size: 26, weight: .black, design: .rounded)).foregroundStyle(Palette.ink)
            Text("It's built by a tiny team and free to play. If it's brightened your day, a small tip helps keep the puppies coming — no pressure at all.")
                .multilineTextAlignment(.center)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Palette.inkSoft)
                .padding(.horizontal, 32)
            Spacer()

            VStack(spacing: 10) {
                ForEach(iap.tipProducts, id: \.id) { product in
                    Button {
                        Task {
                            if await iap.purchaseTip(product) { haptics.unlock(); dismiss() }
                        }
                    } label: {
                        HStack {
                            Text(product.displayName).font(.system(size: 16, weight: .heavy, design: .rounded))
                            Spacer()
                            Text(product.displayPrice).font(.system(size: 16, weight: .heavy, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18).padding(.vertical, 14)
                        .background(Palette.accent, in: Capsule())
                    }
                    .disabled(iap.purchaseInFlight)
                }
            }
            .padding(.horizontal, 32)

            Button("Maybe later") { dismiss() }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.inkSoft)
            Button("Don't ask again") { iap.stopTipReminders(); dismiss() }
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Palette.inkSoft.opacity(0.7))
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .pupBackground()
    }
}
