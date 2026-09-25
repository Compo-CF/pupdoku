import Foundation

/// The full persisted player state: progression, stats, streaks, entitlements,
/// settings, and unlocked achievements. Encoded to one JSON file by
/// `Persistence` and mirrored to CloudKit by `CloudSync`.
struct GameState: Codable, Equatable {

    // MARK: - Progression & stats
    /// Wins keyed by difficulty raw value ("0"..."4"). Drives size unlocks.
    var winsByDifficulty: [Int: Int] = [:]
    /// Best (lowest) completion time keyed by difficulty raw value.
    var bestTimes: [String: TimeInterval] = [:]

    var totalWins: Int = 0
    var totalHintsUsed: Int = 0
    var totalMistakes: Int = 0
    var perfectWins: Int = 0          // no mistakes, no hints
    var totalPlaySeconds: TimeInterval = 0

    // MARK: - Streaks (Daily Puzzle)
    var dailyStreak: Int = 0
    var longestDailyStreak: Int = 0
    var lastDailyEpochDay: Int = 0

    // MARK: - Entitlements
    var removeAdsOwned: Bool = false
    var hintBalance: Int = 3

    // MARK: - Achievements
    var unlockedAchievements: Set<String> = []

    // MARK: - Settings
    var soundOn: Bool = true
    var musicOn: Bool = true
    var hapticsOn: Bool = true
    var highlightConflicts: Bool = true   // paint conflicting puppies red
    var showTimer: Bool = true
    var showMistakeCounter: Bool = true
    var colorblindLabels: Bool = false    // show 2-letter breed codes on puppies

    // MARK: - Housekeeping
    var hasSeenOnboarding: Bool = false
    var savedGame: QueensSavedProgress?

    init() {}

    // MARK: - Progression
    static let winsToUnlockNext = 3

    func wins(for difficulty: Difficulty) -> Int { winsByDifficulty[difficulty.rawValue] ?? 0 }

    /// Puppy (5×5) always open; each larger size opens after 3 wins on the previous.
    func isUnlocked(_ difficulty: Difficulty) -> Bool {
        guard let prev = difficulty.previous else { return true }
        return wins(for: prev) >= Self.winsToUnlockNext
    }

    func winsUntilUnlock(_ difficulty: Difficulty) -> Int {
        guard let prev = difficulty.previous else { return 0 }
        return max(0, Self.winsToUnlockNext - wins(for: prev))
    }

    func bestTime(for spec: PuzzleSpec) -> TimeInterval? { bestTimes[spec.key] }

    // MARK: - Recording a win
    @discardableResult
    mutating func recordWin(spec: PuzzleSpec,
                            elapsed: TimeInterval,
                            mistakes: Int,
                            hintsUsed: Int,
                            isDaily: Bool,
                            todayEpochDay: Int) -> [String] {
        winsByDifficulty[spec.difficulty.rawValue, default: 0] += 1
        totalWins += 1
        totalMistakes += mistakes
        totalHintsUsed += hintsUsed
        totalPlaySeconds += elapsed
        if mistakes == 0 && hintsUsed == 0 { perfectWins += 1 }

        if let prev = bestTimes[spec.key] { if elapsed < prev { bestTimes[spec.key] = elapsed } }
        else { bestTimes[spec.key] = elapsed }

        if isDaily { recordDailyCompletion(todayEpochDay: todayEpochDay) }
        savedGame = nil
        return AchievementCatalog.evaluate(into: &self)
    }

    private mutating func recordDailyCompletion(todayEpochDay: Int) {
        guard todayEpochDay != lastDailyEpochDay else { return }
        dailyStreak = (todayEpochDay == lastDailyEpochDay + 1) ? dailyStreak + 1 : 1
        lastDailyEpochDay = todayEpochDay
        longestDailyStreak = max(longestDailyStreak, dailyStreak)
    }

    mutating func expireDailyStreakIfStale(todayEpochDay: Int) {
        if dailyStreak > 0, todayEpochDay > lastDailyEpochDay + 1 { dailyStreak = 0 }
    }

    func completedDaily(today: Int) -> Bool { today == lastDailyEpochDay }
}

extension Date {
    /// Days since the Unix epoch in UTC — a stable per-day bucket for streaks + daily seed.
    var epochDayUTC: Int { Int((timeIntervalSince1970 / 86400).rounded(.down)) }
}
