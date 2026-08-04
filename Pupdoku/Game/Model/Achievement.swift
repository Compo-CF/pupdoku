import Foundation

/// A single unlockable achievement. `id` is stable and also used as the Game
/// Center achievement identifier (configure matching IDs in App Store Connect).
struct Achievement: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let emoji: String
    /// Given the current state, is this earned? Pure function of `GameState`.
    let isEarned: (GameState) -> Bool

    static func == (lhs: Achievement, rhs: Achievement) -> Bool { lhs.id == rhs.id }
}

enum AchievementCatalog {
    /// Ordered for display (roughly easiest → hardest).
    static let all: [Achievement] = [
        Achievement(id: "first_win", title: "First Best Friend",
                    detail: "Complete your very first puzzle.", emoji: "🐶") { $0.totalWins >= 1 },

        Achievement(id: "unlock_six", title: "Growing Pack",
                    detail: "Unlock the 6 × 6 boards.", emoji: "🐕") { $0.isUnlocked(.six) },

        Achievement(id: "unlock_nine", title: "Full Pack",
                    detail: "Unlock the 9 × 9 boards.", emoji: "🐺") { $0.isUnlocked(.nine) },

        Achievement(id: "wins_10", title: "Regular at the Park",
                    detail: "Win 10 puzzles.", emoji: "🌳") { $0.totalWins >= 10 },

        Achievement(id: "perfect_5", title: "Flawless Fetch",
                    detail: "Win 5 puzzles with no mistakes and no hints.", emoji: "🎾") { $0.perfectWins >= 5 },

        Achievement(id: "nine_hard", title: "Top Dog",
                    detail: "Beat a 9 × 9 puzzle on Hard.", emoji: "🏆") { ($0.winsBySpec["9-3"] ?? 0) >= 1 },

        Achievement(id: "zoomies", title: "Zoomies",
                    detail: "Finish any 9 × 9 in under 5 minutes.", emoji: "💨") { state in
            state.bestTimes.contains { $0.key.hasPrefix("9-") && $0.value < 300 }
        },

        Achievement(id: "daily_7", title: "Week of Walkies",
                    detail: "Keep a 7-day Daily Puzzle streak.", emoji: "🦴") { $0.longestDailyStreak >= 7 },

        Achievement(id: "daily_30", title: "Loyal Companion",
                    detail: "Keep a 30-day Daily Puzzle streak.", emoji: "❤️") { $0.longestDailyStreak >= 30 },

        Achievement(id: "wins_50", title: "Pack Leader",
                    detail: "Win 50 puzzles.", emoji: "👑") { $0.totalWins >= 50 },
    ]

    static func achievement(_ id: String) -> Achievement? { all.first { $0.id == id } }

    /// Mark any newly-earned achievements on `state`, returning the IDs that were
    /// just unlocked this call (so the UI / Game Center can react).
    static func evaluate(into state: inout GameState) -> [String] {
        var newlyUnlocked: [String] = []
        for a in all where !state.unlockedAchievements.contains(a.id) && a.isEarned(state) {
            state.unlockedAchievements.insert(a.id)
            newlyUnlocked.append(a.id)
        }
        return newlyUnlocked
    }
}
