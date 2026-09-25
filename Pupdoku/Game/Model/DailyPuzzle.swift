import Foundation

/// Produces the one-per-day puzzle. Everyone who opens Pupdoku on the same UTC
/// date gets the identical board, which is what makes the Daily Streak fair and
/// the leaderboard comparable.
enum DailyPuzzle {

    /// A mid/large board, difficulty rotating by weekday (weekends gentler).
    static func spec(for date: Date) -> PuzzleSpec {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .current
        let weekday = cal.component(.weekday, from: date) // 1=Sun ... 7=Sat
        let difficulty: Difficulty
        switch weekday {
        case 1, 7: difficulty = .easy     // weekends: 6×6
        case 2, 3: difficulty = .medium   // 7×7
        default:   difficulty = .hard     // midweek: 8×8
        }
        return PuzzleSpec(difficulty: difficulty)
    }

    static func puzzle(for date: Date) -> QueensPuzzle {
        QueensPuzzle.generate(spec: spec(for: date), seed: SeededRNG.dailySeed(for: date))
    }

    static func label(for date: Date) -> String {
        "Daily · \(spec(for: date).difficulty.displayName)"
    }
}
