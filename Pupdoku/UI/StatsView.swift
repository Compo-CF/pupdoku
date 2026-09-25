import SwiftUI

/// Player statistics: totals, streaks, per-size wins, and best times.
struct StatsView: View {
    @Environment(GameStore.self) private var store
    @Environment(GameCenterManager.self) private var gameCenter
    @Environment(\.dismiss) private var dismiss

    @State private var showGameCenter = false
    private var s: GameState { store.state }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    grid([
                        ("Puzzles Solved", "\(s.totalWins)"),
                        ("Perfect Clears", "\(s.perfectWins)"),
                        ("Daily Streak", "\(s.dailyStreak)"),
                        ("Longest Streak", "\(s.longestDailyStreak)"),
                        ("Hints Used", "\(s.totalHintsUsed)"),
                        ("Time Played", formatClock(s.totalPlaySeconds)),
                    ])

                    section("Wins by Size") {
                        ForEach(Difficulty.allCases) { d in
                            row("\(d.sizeLabel)  ·  \(d.displayName)", "\(s.wins(for: d))")
                        }
                    }

                    section("Best Times") {
                        let entries = bestTimeEntries()
                        if entries.isEmpty {
                            Text("Solve a board to set your first record!")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(Palette.inkSoft)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            ForEach(entries, id: \.0) { entry in row(entry.0, formatClock(entry.1)) }
                        }
                    }
                }
                .padding(20)
            }
            .pupBackground()
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                if gameCenter.isAuthenticated {
                    ToolbarItem(placement: .primaryAction) {
                        Button { showGameCenter = true } label: { Image(systemName: "trophy.fill") }
                            .accessibilityLabel("Open leaderboards in Game Center")
                    }
                }
            }
            .fullScreenCover(isPresented: $showGameCenter) {
                GameCenterView(panel: .leaderboards).ignoresSafeArea()
            }
        }
    }

    private func bestTimeEntries() -> [(String, TimeInterval)] {
        var out: [(String, TimeInterval)] = []
        for d in Difficulty.allCases {
            if let t = s.bestTime(for: PuzzleSpec(difficulty: d)) {
                out.append(("\(d.sizeLabel) · \(d.displayName)", t))
            }
        }
        return out
    }

    @ViewBuilder
    private func grid(_ items: [(String, String)]) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(items, id: \.0) { item in
                VStack(spacing: 4) {
                    Text(item.1).font(.system(size: 26, weight: .black, design: .rounded)).foregroundStyle(Palette.ink)
                    Text(item.0).font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(Palette.inkSoft)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(Palette.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 5, y: 2)
            }
        }
    }

    @ViewBuilder
    private func section(_ title: String, @ViewBuilder _ content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(Palette.inkSoft)
            VStack(spacing: 8) { content() }.pupCard()
        }
    }

    @ViewBuilder
    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 15, weight: .medium, design: .rounded)).foregroundStyle(Palette.ink)
            Spacer()
            Text(value).font(.system(size: 15, weight: .heavy, design: .rounded).monospacedDigit()).foregroundStyle(Palette.ink)
        }
    }
}
