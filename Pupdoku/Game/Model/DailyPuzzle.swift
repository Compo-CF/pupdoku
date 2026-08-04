import Foundation

/// Produces the one-per-day puzzle. Every player who opens Pupdoku on the same
/// UTC date is handed the identical board (same size, difficulty and layout),
/// which is what makes the Daily Streak fair and comparable on the leaderboard.
enum DailyPuzzle {

    /// The daily is always a 9 × 9 so it's a "real" sudoku, with the difficulty
    /// rotating through the week to keep it fresh (weekends run easier).
    static func spec(for date: Date) -> PuzzleSpec {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .current
        let weekday = cal.component(.weekday, from: date) // 1 = Sunday ... 7 = Saturday
        let difficulty: Difficulty
        switch weekday {
        case 1, 7:      difficulty = .easy    // weekends: gentle
        case 2, 3:      difficulty = .medium
        default:        difficulty = .hard    // midweek: challenge
        }
        return PuzzleSpec(size: .nine, difficulty: difficulty)
    }

    static func puzzle(for date: Date) -> Puzzle {
        let spec = spec(for: date)
        let seed = SeededRNG.dailySeed(for: date)
        return Puzzle.generate(spec: spec, seed: seed)
    }

    /// A short human label, e.g. "Daily · Hard".
    static func label(for date: Date) -> String {
        "Daily · \(spec(for: date).difficulty.displayName)"
    }
}
