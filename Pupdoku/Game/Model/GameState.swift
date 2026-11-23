import Foundation

/// The full persisted player state: progression, stats, streaks, entitlements,
/// the Bones economy (v3.0), settings, and unlocked achievements. Encoded to one
/// JSON file by Persistence and mirrored to CloudKit by CloudSync.
struct GameState: Codable, Equatable {

    // MARK: - Progression & stats
    var winsByDifficulty: [Int: Int] = [:]
    var bestTimes: [String: TimeInterval] = [:]

    var totalWins: Int = 0
    var totalHintsUsed: Int = 0
    var totalMistakes: Int = 0
    var perfectWins: Int = 0
    var totalPlaySeconds: TimeInterval = 0

    // MARK: - Streaks (Daily Puzzle)
    var dailyStreak: Int = 0
    var longestDailyStreak: Int = 0
    var lastDailyEpochDay: Int = 0

    // MARK: - Entitlements
    var removeAdsOwned: Bool = false
    var hintBalance: Int = 3

    // MARK: - Bones economy (v3.0)
    var bones: Int = 0
    var ownedThemes: Set<String> = ["classic"]
    var selectedTheme: String = "classic"
    var ownedEventPasses: Set<String> = []
    /// Bones awarded by the most recent win (for the win screen).
    var lastWinBones: Int = 0

    // MARK: - Event challenges (3.3)
    // Optional so saves written by older versions still decode (synthesized
    // Codable requires every non-optional key).
    /// challenge id -> UTC epoch days on which a Daily was solved inside its window.
    var challengeDays: [String: [Int]]?
    /// challenge ids whose reward has been granted.
    var completedChallenges: Set<String>?
    /// Set by the most recent win when it counted toward a challenge (win screen).
    var lastChallengeNote: String?

    // MARK: - Achievements
    var unlockedAchievements: Set<String> = []

    // MARK: - Settings
    var soundOn: Bool = true
    var musicOn: Bool = true
    var hapticsOn: Bool = true
    var highlightConflicts: Bool = true
    var showTimer: Bool = true
    var showMistakeCounter: Bool = true
    var colorblindLabels: Bool = false

    // MARK: - Housekeeping
    var hasSeenOnboarding: Bool = false
    var savedGame: QueensSavedProgress?

    init() {}

    // MARK: - Progression
    static let winsToUnlockNext = 3

    func wins(for difficulty: Difficulty) -> Int { winsByDifficulty[difficulty.rawValue] ?? 0 }

    func isUnlocked(_ difficulty: Difficulty) -> Bool {
        guard let prev = difficulty.previous else { return true }
        return wins(for: prev) >= Self.winsToUnlockNext
    }

    func winsUntilUnlock(_ difficulty: Difficulty) -> Int {
        guard let prev = difficulty.previous else { return 0 }
        return max(0, Self.winsToUnlockNext - wins(for: prev))
    }

    func bestTime(for spec: PuzzleSpec) -> TimeInterval? { bestTimes[spec.key] }

    // MARK: - Bones earning
    /// Bones awarded for solving a board: base + size bonus + perfect bonus.
    static func bonesForWin(spec: PuzzleSpec, mistakes: Int, hintsUsed: Int, isDaily: Bool) -> Int {
        var b = 10 + spec.difficulty.rawValue * 5       // 10..30 by size
        if mistakes == 0 && hintsUsed == 0 { b += 10 }  // perfect bonus
        if isDaily { b += 15 }                          // daily bonus
        return b
    }

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

        let earned = Self.bonesForWin(spec: spec, mistakes: mistakes, hintsUsed: hintsUsed, isDaily: isDaily)
        bones += earned
        lastWinBones = earned

        lastChallengeNote = nil
        if isDaily {
            recordDailyCompletion(todayEpochDay: todayEpochDay)
            recordChallengeDaily(todayEpochDay: todayEpochDay)
        }
        savedGame = nil
        return AchievementCatalog.evaluate(into: &self)
    }

    private mutating func recordDailyCompletion(todayEpochDay: Int) {
        guard todayEpochDay != lastDailyEpochDay else { return }
        dailyStreak = (todayEpochDay == lastDailyEpochDay + 1) ? dailyStreak + 1 : 1
        lastDailyEpochDay = todayEpochDay
        longestDailyStreak = max(longestDailyStreak, dailyStreak)
    }

    // MARK: - Event challenges
    func challengeProgress(_ c: EventChallenge) -> Int { min(c.goal, Set(challengeDays?[c.id] ?? []).count) }
    func isChallengeComplete(_ c: EventChallenge) -> Bool { completedChallenges?.contains(c.id) ?? false }

    /// Counts today's Daily toward every open challenge (once per UTC day) and
    /// grants the reward the first time the goal is reached.
    private mutating func recordChallengeDaily(todayEpochDay: Int) {
        for c in EventChallengeCatalog.all where c.isActive(today: todayEpochDay) {
            var days = Set(challengeDays?[c.id] ?? [])
            guard !days.contains(todayEpochDay) else { continue }
            days.insert(todayEpochDay)
            var map = challengeDays ?? [:]
            map[c.id] = days.sorted()
            challengeDays = map
            let progress = min(c.goal, days.count)
            if progress >= c.goal && !isChallengeComplete(c) {
                var done = completedChallenges ?? []
                done.insert(c.id)
                completedChallenges = done
                ownedThemes.insert(c.rewardThemeId)
                bones += c.rewardBones
                lastWinBones += c.rewardBones
                lastChallengeNote = "\(c.emoji) \(c.name) complete! \(ThemeCatalog.theme(c.rewardThemeId).name) theme unlocked"
            } else if !isChallengeComplete(c) {
                lastChallengeNote = "\(c.emoji) \(c.name): \(progress)/\(c.goal) Dailies"
            }
        }
    }

    mutating func expireDailyStreakIfStale(todayEpochDay: Int) {
        if dailyStreak > 0, todayEpochDay > lastDailyEpochDay + 1 { dailyStreak = 0 }
    }

    func completedDaily(today: Int) -> Bool { today == lastDailyEpochDay }
}

extension Date {
    var epochDayUTC: Int { Int((timeIntervalSince1970 / 86400).rounded(.down)) }
}
