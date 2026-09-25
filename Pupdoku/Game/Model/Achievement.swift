import Foundation

/// A single unlockable achievement. `id` is stable and reused as the Game Center
/// achievement identifier — these IDs are already configured in App Store Connect,
/// so they must NOT change even though the game's mechanic did.
struct Achievement: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let emoji: String
    let isEarned: (GameState) -> Bool

    static func == (lhs: Achievement, rhs: Achievement) -> Bool { lhs.id == rhs.id }
}

enum AchievementCatalog {
    /// Ordered easiest → hardest. IDs are fixed (ASC/Game Center); wording maps to
    /// the "Find the Puppies" mechanic.
    static let all: [Achievement] = [
        Achievement(id: "first_win", title: "First Best Friend",
                    detail: "Solve your very first board.", emoji: "🐶") { $0.totalWins >= 1 },

        Achievement(id: "unlock_six", title: "Growing Pack",
                    detail: "Unlock the 7 × 7 boards.", emoji: "🐕") { $0.isUnlocked(.medium) },

        Achievement(id: "unlock_nine", title: "Full Kennel",
                    detail: "Unlock the 9 × 9 boards.", emoji: "🐺") { $0.isUnlocked(.expert) },

        Achievement(id: "wins_10", title: "Regular at the Park",
                    detail: "Solve 10 boards.", emoji: "🌳") { $0.totalWins >= 10 },

        Achievement(id: "perfect_5", title: "Flawless Fetch",
                    detail: "Solve 5 boards with no mistakes and no hints.", emoji: "🎾") { $0.perfectWins >= 5 },

        Achievement(id: "nine_hard", title: "Top Dog",
                    detail: "Solve a 9 × 9 (Expert) board.", emoji: "🏆") { $0.wins(for: .expert) >= 1 },

        Achievement(id: "zoomies", title: "Zoomies",
                    detail: "Solve a 9 × 9 in under 5 minutes.", emoji: "💨") { ($0.bestTimes["\(Difficulty.expert.rawValue)"] ?? .greatestFiniteMagnitude) < 300 },

        Achievement(id: "daily_7", title: "Week of Walkies",
                    detail: "Keep a 7-day Daily Puzzle streak.", emoji: "🦴") { $0.longestDailyStreak >= 7 },

        Achievement(id: "daily_30", title: "Loyal Companion",
                    detail: "Keep a 30-day Daily Puzzle streak.", emoji: "❤️") { $0.longestDailyStreak >= 30 },

        Achievement(id: "wins_50", title: "Pack Leader",
                    detail: "Solve 50 boards.", emoji: "👑") { $0.totalWins >= 50 },
    ]

    static func achievement(_ id: String) -> Achievement? { all.first { $0.id == id } }

    static func evaluate(into state: inout GameState) -> [String] {
        var newly: [String] = []
        for a in all where !state.unlockedAchievements.contains(a.id) && a.isEarned(state) {
            state.unlockedAchievements.insert(a.id)
            newly.append(a.id)
        }
        return newly
    }
}
