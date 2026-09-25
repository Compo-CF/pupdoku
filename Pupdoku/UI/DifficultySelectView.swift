import SwiftUI

/// Size/difficulty picker. Each tier is a board size (5x5...9x9) that unlocks as
/// the player wins on the previous size. Selecting one starts the game.
struct DifficultySelectView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let onStart: (PuzzleSpec) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Difficulty.allCases) { d in
                        row(for: d)
                    }
                }
                .padding(20)
            }
            .pupBackground()
            .navigationTitle("New Puzzle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }

    @ViewBuilder
    private func row(for d: Difficulty) -> some View {
        let unlocked = store.state.isUnlocked(d)
        let spec = PuzzleSpec(difficulty: d)
        Button {
            if unlocked { onStart(spec) }
        } label: {
            HStack(spacing: 14) {
                Text(d.emoji).font(.system(size: 28))
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(d.sizeLabel).font(.system(size: 18, weight: .heavy, design: .rounded))
                        Text(d.displayName).font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Palette.inkSoft)
                    }
                    if unlocked {
                        Text(d.subtitle).font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Palette.inkSoft)
                    } else {
                        Label("Win \(store.state.winsUntilUnlock(d)) more to unlock", systemImage: "lock.fill")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.inkSoft)
                    }
                }
                Spacer()
                if unlocked, let best = store.state.bestTime(for: spec) {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(formatClock(best)).font(.system(size: 13, weight: .heavy, design: .rounded).monospacedDigit())
                        Text("best").font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(Palette.inkSoft)
                    }
                }
                Image(systemName: unlocked ? "chevron.right" : "lock.fill")
                    .font(.system(size: 13, weight: .bold)).foregroundStyle(Palette.inkSoft)
            }
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 16).padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.line, lineWidth: 1))
            .opacity(unlocked ? 1 : 0.6)
            .shadow(color: .black.opacity(0.04), radius: 5, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
    }
}
