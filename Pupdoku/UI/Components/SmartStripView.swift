import SwiftUI

/// Fills the space beneath the board. For a non-subscriber it's a glossy Parade
/// Pass upsell; for a subscriber it flips to a useful stats strip (Bones, daily
/// streak, progress to the next board size) so a paying player is never nagged.
struct SmartStripView: View {
    @Environment(GameStore.self) private var store
    let difficulty: Difficulty
    let onUpsell: () -> Void

    var body: some View {
        if store.subscriptionActive {
            statsStrip
        } else {
            upsell
        }
    }

    // MARK: - Non-subscriber: Parade Pass upsell

    private var upsell: some View {
        Button(action: onUpsell) {
            ZStack(alignment: .leading) {
                Text("🎪")
                    .font(.system(size: 64))
                    .opacity(0.18)
                    .offset(x: 2, y: 14)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .clipped()

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("🎪 Parade Pass")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                        Text("Play ad-free with unlimited hints")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .opacity(0.92)
                    }
                    Spacer(minLength: 8)
                    Text("Try it")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.paradeInk)
                        .padding(.horizontal, 16).padding(.vertical, 9)
                        .background(.white, in: Capsule())
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
            }
            .foregroundStyle(.white)
            .background(Gradients.parade, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Palette.parade1.opacity(0.35), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subscriber: stats strip

    private var statsStrip: some View {
        HStack(spacing: 0) {
            stat("🦴 \(store.bones)", "Bones")
            divider
            stat("🔥 \(store.state.dailyStreak)", "Streak")
            divider
            progressStat
        }
        .padding(.vertical, 12).padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private var divider: some View {
        Rectangle().fill(Palette.line.opacity(0.6)).frame(width: 1, height: 26)
    }

    @ViewBuilder
    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.ink)
            Text(label).font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.inkSoft).textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }

    /// Progress toward unlocking the next board size (or total wins once maxed).
    @ViewBuilder
    private var progressStat: some View {
        if let next = Difficulty(rawValue: difficulty.rawValue + 1), !store.state.isUnlocked(next) {
            let have = min(store.state.wins(for: difficulty), GameState.winsToUnlockNext)
            stat("\(have)/\(GameState.winsToUnlockNext)", "to \(next.sizeLabel)")
        } else {
            stat("\(store.state.totalWins)", "Wins")
        }
    }
}
