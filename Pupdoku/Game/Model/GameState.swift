import Foundation

/// The full persisted state of a player: progression, statistics, streaks,
/// entitlements, settings, and unlocked achievements. One value, encoded to a
/// single JSON file by `Persistence` and mirrored to CloudKit by `CloudSync`.
struct GameState: Codable, Equatable {

    // MARK: - Progression & stats

    /// Wins keyed by grid size raw value (4/6/9). Drives size unlocks.
    var winsBySize: [Int: Int] = [:]
    /// Wins keyed by "size-difficulty" (e.g. "9-3"). Fine-grained stats.
    var winsBySpec: [String: Int] = [:]
    /// Best (lowest) completion time keyed by "size-difficulty".
    var bestTimes: [String: TimeInterval] = [:]

    var totalWins: Int = 0
    var totalHintsUsed: Int = 0
    var totalMistakes: Int = 0
    var perfectWins: Int = 0        // won with zero mistakes and zero hints
    var totalPlaySeconds: TimeInterval = 0

    // MARK: - Streaks (Daily Puzzle)

    var dailyStreak: Int = 0
    var longestDailyStreak: Int = 0
    /// Epoch-day (days since 1970, UTC) of the last completed daily.
    var lastDailyEpochDay: Int = 0

    // MARK: - Entitlements

    var removeAdsOwned: Bool = false
    /// Free + purchased hints available to spend. New players start with a few.
    var hintBalance: Int = 3

    // MARK: - Achievements

    var unlockedAchievements: Set<String> = []

    // MARK: - Settings

    var soundOn: Bool = true
    var hapticsOn: Bool = true
    var highlightPeers: Bool = true      // dim/emphasize row+col+box of selection
    var highlightSameBreed: Bool = true  // emphasize all cells of the selected breed
    var autoRemoveNotes: Bool = true     // clear peer notes when placing a breed
    var showTimer: Bool = true
    var showMistakeCounter: Bool = true
    var colorblindLabels: Bool = false   // show 2-letter breed codes on tiles

    // MARK: - Onboarding / housekeeping

    var hasSeenOnboarding: Bool = false
    /// A saved, resumable in-progress game (nil if none).
    var savedGame: SavedProgress?

    init() {}

    // MARK: - Progression logic

    static let winsToUnlockSix  = 3
    static let winsToUnlockNine = 3

    func wins(for size: GridSize) -> Int { winsBySize[size.order] ?? 0 }

    /// 4×4 is always open; 6×6 opens after enough 4×4 wins; 9×9 after 6×6 wins.
    func isUnlocked(_ size: GridSize) -> Bool {
        switch size {
        case .four: return true
        case .six:  return wins(for: .four) >= Self.winsToUnlockSix
        case .nine: return wins(for: .six)  >= Self.winsToUnlockNine
        }
    }

    /// Wins still needed before `size` unlocks (0 if already unlocked).
    func winsUntilUnlock(_ size: GridSize) -> Int {
        switch size {
        case .four: return 0
        case .six:  return max(0, Self.winsToUnlockSix - wins(for: .four))
        case .nine: return max(0, Self.winsToUnlockNine - wins(for: .six))
        }
    }

    static func specKey(_ spec: PuzzleSpec) -> String { "\(spec.size.order)-\(spec.difficulty.rawValue)" }

    func bestTime(for spec: PuzzleSpec) -> TimeInterval? { bestTimes[Self.specKey(spec)] }

    // MARK: - Recording a win

    /// Fold a completed puzzle into the stats. Returns the set of newly-unlocked
    /// achievement IDs so the caller can present them.
    @discardableResult
    mutating func recordWin(spec: PuzzleSpec,
                            elapsed: TimeInterval,
                            mistakes: Int,
                            hintsUsed: Int,
                            isDaily: Bool,
                            todayEpochDay: Int) -> [String] {
        winsBySize[spec.size.order, default: 0] += 1
        winsBySpec[Self.specKey(spec), default: 0] += 1
        totalWins += 1
        totalMistakes += mistakes
        totalHintsUsed += hintsUsed
        totalPlaySeconds += elapsed
        if mistakes == 0 && hintsUsed == 0 { perfectWins += 1 }

        let key = Self.specKey(spec)
        if let prev = bestTimes[key] {
            if elapsed < prev { bestTimes[key] = elapsed }
        } else {
            bestTimes[key] = elapsed
        }

        if isDaily { recordDailyCompletion(todayEpochDay: todayEpochDay) }

        savedGame = nil
        return AchievementCatalog.evaluate(into: &self)
    }

    private mutating func recordDailyCompletion(todayEpochDay: Int) {
        guard todayEpochDay != lastDailyEpochDay else { return } // already counted today
        if todayEpochDay == lastDailyEpochDay + 1 {
            dailyStreak += 1
        } else {
            dailyStreak = 1
        }
        lastDailyEpochDay = todayEpochDay
        longestDailyStreak = max(longestDailyStreak, dailyStreak)
    }

    /// If the player misses a day, the streak should read as broken. Call on launch.
    mutating func expireDailyStreakIfStale(todayEpochDay: Int) {
        if dailyStreak > 0, todayEpochDay > lastDailyEpochDay + 1 {
            dailyStreak = 0
        }
    }

    /// True if today's daily has already been completed.
    func completedDaily(today: Int) -> Bool { today == lastDailyEpochDay }
}

extension Date {
    /// Days since the Unix epoch in UTC — a stable per-day bucket for streaks
    /// and the daily-puzzle seed.
    var epochDayUTC: Int {
        Int((timeIntervalSince1970 / 86400).rounded(.down))
    }
}
