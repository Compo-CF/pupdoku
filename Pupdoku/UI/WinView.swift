import SwiftUI

/// Celebration shown when a puzzle is solved. Surfaces time (and a new-best
/// badge), the perfect-clear callout, any freshly unlocked achievements, a
/// share button, and the play-again / home actions.
struct WinView: View {
    let spec: PuzzleSpec
    let elapsed: TimeInterval
    let mistakes: Int
    let hintsUsed: Int
    let isDaily: Bool
    let bestTime: TimeInterval?
    let newlyUnlocked: [String]
    let onPlayAgain: () -> Void
    let onHome: () -> Void

    @Environment(IAPManager.self) private var iap
    @State private var pop = false

    private var isPerfect: Bool { mistakes == 0 && hintsUsed == 0 }
    private var isNewBest: Bool { bestTime.map { abs($0 - elapsed) < 0.5 } ?? true }

    private var shareText: String {
        let mode = isDaily ? "the \(spec.difficulty.displayName) Daily" : "a \(spec.difficulty.sizeLabel) \(spec.difficulty.displayName)"
        let perfect = isPerfect ? " with a perfect clear" : ""
        return "I solved \(mode) Pupdoku in \(formatClock(elapsed))\(perfect)! 🐶🐾 Can you beat me? #Pupdoku"
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text(isDaily ? "🦴" : "🏆")
                .font(.system(size: 78))
                .scaleEffect(pop ? 1 : 0.4)
                .rotationEffect(.degrees(pop ? 0 : -20))
                .animation(.spring(response: 0.5, dampingFraction: 0.5), value: pop)

            Text(isDaily ? "Daily Done!" : "Good Dog!")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(Palette.ink)

            VStack(spacing: 10) {
                statRow("Time", formatClock(elapsed), highlight: isNewBest ? "New best!" : nil)
                if isPerfect {
                    Label("Perfect clear — no mistakes, no hints", systemImage: "sparkles")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.success)
                } else {
                    HStack(spacing: 18) {
                        Text("Mistakes: \(mistakes)")
                        Text("Hints: \(hintsUsed)")
                    }
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.inkSoft)
                }
            }
            .pupCard()
            .padding(.horizontal, 32)

            if !newlyUnlocked.isEmpty {
                VStack(spacing: 8) {
                    Text("New Achievement\(newlyUnlocked.count > 1 ? "s" : "")!")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.accentDeep)
                    ForEach(newlyUnlocked, id: \.self) { id in
                        if let a = AchievementCatalog.achievement(id) {
                            Label("\(a.emoji)  \(a.title)", systemImage: "rosette")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(Palette.ink)
                        }
                    }
                }
                .pupCard()
                .padding(.horizontal, 32)
                .transition(.scale.combined(with: .opacity))
            }

            Spacer()

            VStack(spacing: 12) {
                ShareLink(item: shareText) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Palette.card, in: Capsule())
                        .overlay(Capsule().stroke(Palette.line, lineWidth: 1))
                        .foregroundStyle(Palette.ink)
                }

                Button(action: onPlayAgain) {
                    Text(isDaily ? "New Puzzle" : "Play Again")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Palette.accent, in: Capsule())
                        .foregroundStyle(.white)
                }

                Button(action: onHome) {
                    Text("Home")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.inkSoft)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .pupBackground()
        .onAppear { pop = true }
    }

    @ViewBuilder
    private func statRow(_ label: String, _ value: String, highlight: String?) -> some View {
        HStack {
            Text(label).font(.system(size: 15, weight: .medium, design: .rounded)).foregroundStyle(Palette.inkSoft)
            Spacer()
            Text(value).font(.system(size: 18, weight: .heavy, design: .rounded).monospacedDigit()).foregroundStyle(Palette.ink)
            if let highlight {
                Text(highlight)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Palette.success, in: Capsule())
            }
        }
    }
}

/// Shown when the mistake limit is reached.
struct LoseView: View {
    let onRetry: () -> Void
    let onHome: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("🐕‍🦺").font(.system(size: 72))
            Text("Out of Tries")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(Palette.ink)
            Text("Too many mistakes this round.\nShake it off and try a fresh board!")
                .multilineTextAlignment(.center)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Palette.inkSoft)
                .padding(.horizontal, 40)
            Spacer()
            VStack(spacing: 12) {
                Button(action: onRetry) {
                    Text("New Board")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Palette.accent, in: Capsule()).foregroundStyle(.white)
                }
                Button(action: onHome) {
                    Text("Home").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(Palette.inkSoft)
                }
            }
            .padding(.horizontal, 32).padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .pupBackground()
    }
}
