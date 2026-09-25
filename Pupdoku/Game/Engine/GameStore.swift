import Foundation
import Observation

/// App-level coordinator: owns the persisted `GameState`, the active
/// `QueensSession`, and every transition that must also touch persistence
/// (start/resume, win, hints, settings).
@MainActor
@Observable
final class GameStore {
    private(set) var state: GameState
    private let persistence: Persistence

    private(set) var session: QueensSession?
    private(set) var isGenerating = false
    private(set) var isDaily = false
    private(set) var lastUnlockedAchievements: [String] = []

    init(state: GameState, persistence: Persistence) {
        self.state = state
        self.persistence = persistence
    }

    // MARK: - Launch
    func applyLaunch() {
        state.expireDailyStreakIfStale(todayEpochDay: Date().epochDayUTC)
        save()
    }

    var hasSavedGame: Bool { state.savedGame != nil }
    var savedGameLabel: String? { state.savedGame.map { $0.puzzle.difficulty.sizeLabel + " · " + $0.puzzle.difficulty.displayName } }

    // MARK: - Starting games
    func startNewGame(spec: PuzzleSpec) async {
        isDaily = false
        isGenerating = true
        state.savedGame = nil
        let seed = UInt64.random(in: 1...UInt64.max)
        let puzzle = await Self.generate(spec: spec, seed: seed)
        session = QueensSession(puzzle: puzzle)
        isGenerating = false
    }

    func startDaily() async {
        isDaily = true
        isGenerating = true
        let today = Date()
        if let saved = state.savedGame,
           saved.puzzle.seed == SeededRNG.dailySeed(for: today),
           saved.puzzle.spec == DailyPuzzle.spec(for: today) {
            session = QueensSession(puzzle: saved.puzzle, resume: saved)
        } else {
            let puzzle = await Self.generateDaily(for: today)
            session = QueensSession(puzzle: puzzle)
        }
        isGenerating = false
    }

    func resumeSavedGame() {
        guard let saved = state.savedGame else { return }
        isDaily = false
        session = QueensSession(puzzle: saved.puzzle, resume: saved)
    }

    func stashCurrentGame() {
        guard let session, session.status == .playing else { return }
        state.savedGame = session.snapshot()
        save()
    }

    func abandonCurrentGame() {
        session = nil
        state.savedGame = nil
        save()
    }

    // MARK: - Win
    @discardableResult
    func recordWinFromSession() -> [String] {
        guard let session, session.status == .won else { return [] }
        let unlocked = state.recordWin(
            spec: session.puzzle.spec,
            elapsed: session.elapsed,
            mistakes: session.mistakes,
            hintsUsed: session.hintsUsed,
            isDaily: isDaily,
            todayEpochDay: Date().epochDayUTC
        )
        lastUnlockedAchievements = unlocked
        save()
        return unlocked
    }

    // MARK: - Hints
    var hintBalance: Int { state.hintBalance }

    @discardableResult
    func useHintFromBalance() -> Bool {
        guard let session, state.hintBalance > 0 else { return false }
        guard session.useHint() else { return false }
        state.hintBalance -= 1
        save()
        return true
    }

    func grantHints(_ n: Int) {
        guard n > 0 else { return }
        state.hintBalance += n
        save()
    }

    @discardableResult
    func revealWithRewardedHint() -> Bool {
        grantHints(1)
        return useHintFromBalance()
    }

    // MARK: - Entitlements & settings
    func setRemoveAdsOwned(_ owned: Bool) {
        guard state.removeAdsOwned != owned else { return }
        state.removeAdsOwned = owned
        save()
    }

    func updateSettings(_ mutate: (inout GameState) -> Void) { mutate(&state); save() }

    func markOnboardingSeen() { state.hasSeenOnboarding = true; save() }

    func resetProgress() {
        var fresh = GameState()
        fresh.hasSeenOnboarding = true
        fresh.removeAdsOwned = state.removeAdsOwned
        fresh.soundOn = state.soundOn
        fresh.musicOn = state.musicOn
        fresh.hapticsOn = state.hapticsOn
        fresh.highlightConflicts = state.highlightConflicts
        fresh.showTimer = state.showTimer
        fresh.showMistakeCounter = state.showMistakeCounter
        fresh.colorblindLabels = state.colorblindLabels
        session = nil
        state = fresh
        save()
    }

    func replaceState(_ new: GameState) { state = new; save() }

    // MARK: - Persistence
    func save() { try? persistence.save(state: state) }

    // MARK: - Generation (off the main actor)
    private static func generate(spec: PuzzleSpec, seed: UInt64) async -> QueensPuzzle {
        await Task.detached(priority: .userInitiated) { QueensPuzzle.generate(spec: spec, seed: seed) }.value
    }
    private static func generateDaily(for date: Date) async -> QueensPuzzle {
        await Task.detached(priority: .userInitiated) { DailyPuzzle.puzzle(for: date) }.value
    }
}
