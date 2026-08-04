import Foundation
import Observation

/// The app-level coordinator. Owns the persisted `GameState`, the active
/// `PuzzleSession` (if any), and mediates every state transition that must also
/// touch persistence: starting/resuming a game, recording a win or loss,
/// spending and granting hints, and applying settings.
///
/// Mirrors Cosmica's `GameEngine` role but for a session-based puzzle game.
@MainActor
@Observable
final class GameStore {
    private(set) var state: GameState
    private let persistence: Persistence

    /// The puzzle currently in play, or nil on the menus.
    private(set) var session: PuzzleSession?
    private(set) var isGenerating = false

    /// True while `session` is a Daily Puzzle (affects streak accounting + win UI).
    private(set) var isDaily = false

    /// IDs unlocked by the most recent win, for the win screen / GC reporting.
    private(set) var lastUnlockedAchievements: [String] = []

    init(state: GameState, persistence: Persistence) {
        self.state = state
        self.persistence = persistence
    }

    // MARK: - Launch housekeeping

    func applyLaunch() {
        state.expireDailyStreakIfStale(todayEpochDay: Date().epochDayUTC)
        save()
    }

    var hasSavedGame: Bool { state.savedGame != nil }

    var savedGameLabel: String? {
        guard let s = state.savedGame else { return nil }
        return "\(s.spec.size.displayName) · \(s.spec.difficulty.displayName)"
    }

    // MARK: - Starting games

    /// Generate a fresh random puzzle for `spec` off the main actor, then install
    /// it as the active session.
    func startNewGame(spec: PuzzleSpec) async {
        isDaily = false
        isGenerating = true
        state.savedGame = nil
        let seed = UInt64.random(in: 1...UInt64.max)
        let puzzle = await Self.generate(spec: spec, seed: seed)
        session = makeSession(puzzle: puzzle)
        isGenerating = false
    }

    /// Start (or resume) today's Daily Puzzle.
    func startDaily() async {
        isDaily = true
        isGenerating = true
        let today = Date()
        // Resume an in-progress daily if the saved game is today's daily.
        if let saved = state.savedGame,
           saved.seed == SeededRNG.dailySeed(for: today),
           saved.spec == DailyPuzzle.spec(for: today) {
            session = makeSession(puzzle: saved.puzzle, resume: saved)
        } else {
            let puzzle = await Self.generateDaily(for: today)
            session = makeSession(puzzle: puzzle)
        }
        isGenerating = false
    }

    /// Resume a previously-saved non-daily game.
    func resumeSavedGame() {
        guard let saved = state.savedGame else { return }
        isDaily = false
        session = makeSession(puzzle: saved.puzzle, resume: saved)
    }

    private func makeSession(puzzle: Puzzle, resume: SavedProgress? = nil) -> PuzzleSession {
        let s = PuzzleSession(puzzle: puzzle, resume: resume)
        s.respectsAutoNotes = state.autoRemoveNotes
        return s
    }

    /// Persist the in-progress game so it survives a quit. Call when leaving the
    /// board without finishing.
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

    // MARK: - Win / loss

    /// Record a completed win. Returns the newly-unlocked achievement IDs.
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

    func recordLossFromSession() {
        guard let session, session.status == .lost else { return }
        state.totalMistakes += session.mistakes
        state.totalPlaySeconds += session.elapsed
        state.savedGame = nil
        save()
    }

    // MARK: - Hints

    var hintBalance: Int { state.hintBalance }

    /// Spend one hint from the balance to reveal a cell. Returns false if the
    /// balance is empty or there's nothing to reveal (UI then offers the shop /
    /// a rewarded ad).
    @discardableResult
    func useHintFromBalance() -> Bool {
        guard let session, state.hintBalance > 0 else { return false }
        guard session.useHint() else { return false }
        state.hintBalance -= 1
        save()
        return true
    }

    /// Credit hints (from a purchase or a rewarded ad).
    func grantHints(_ n: Int) {
        guard n > 0 else { return }
        state.hintBalance += n
        save()
    }

    /// Reward flow: grant one hint then immediately spend it to reveal a cell.
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

    /// Mutate settings via a closure and persist once.
    func updateSettings(_ mutate: (inout GameState) -> Void) {
        mutate(&state)
        save()
    }

    func markOnboardingSeen() {
        state.hasSeenOnboarding = true
        save()
    }

    /// Wipe local progress (keeps onboarding-seen so we don't re-teach). Purchases
    /// live with Apple and are untouched.
    func resetProgress() {
        var fresh = GameState()
        fresh.hasSeenOnboarding = true
        fresh.removeAdsOwned = state.removeAdsOwned
        // Carry over settings so a reset doesn't also flip the player's prefs.
        fresh.soundOn = state.soundOn
        fresh.hapticsOn = state.hapticsOn
        fresh.highlightPeers = state.highlightPeers
        fresh.highlightSameBreed = state.highlightSameBreed
        fresh.autoRemoveNotes = state.autoRemoveNotes
        fresh.showTimer = state.showTimer
        fresh.showMistakeCounter = state.showMistakeCounter
        fresh.colorblindLabels = state.colorblindLabels
        session = nil
        state = fresh
        save()
    }

    // MARK: - Cloud reconcile

    func replaceState(_ new: GameState) {
        state = new
        save()
    }

    // MARK: - Persistence

    func save() { try? persistence.save(state: state) }

    // MARK: - Generation (off the main actor)

    private static func generate(spec: PuzzleSpec, seed: UInt64) async -> Puzzle {
        await Task.detached(priority: .userInitiated) {
            Puzzle.generate(spec: spec, seed: seed)
        }.value
    }

    private static func generateDaily(for date: Date) async -> Puzzle {
        await Task.detached(priority: .userInitiated) {
            DailyPuzzle.puzzle(for: date)
        }.value
    }
}
