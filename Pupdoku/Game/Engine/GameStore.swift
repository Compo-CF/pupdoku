import Foundation
import Observation

/// App-level coordinator: owns the persisted GameState, the active QueensSession,
/// the Bones economy, and every transition that also touches persistence.
@MainActor
@Observable
final class GameStore {
    private(set) var state: GameState
    private let persistence: Persistence

    private(set) var session: QueensSession?
    private(set) var isGenerating = false
    private(set) var isDaily = false
    private(set) var lastUnlockedAchievements: [String] = []

    /// Mirrors IAPManager.subscriptionActive (Parade Pass): unlimited hints + ad-free.
    var subscriptionActive = false

    /// Cost in Bones to reveal one hint (when not subscribed / out of free hints).
    static let hintBonesCost = 15

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
        isDaily = false; isGenerating = true; state.savedGame = nil
        let seed = UInt64.random(in: 1...UInt64.max)
        let puzzle = await Self.generate(spec: spec, seed: seed)
        session = QueensSession(puzzle: puzzle)
        isGenerating = false
    }

    func startDaily() async {
        isDaily = true; isGenerating = true
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
        state.savedGame = session.snapshot(); save()
    }

    func abandonCurrentGame() { session = nil; state.savedGame = nil; save() }

    // MARK: - Win
    @discardableResult
    func recordWinFromSession() -> [String] {
        guard let session, session.status == .won else { return [] }
        let unlocked = state.recordWin(
            spec: session.puzzle.spec, elapsed: session.elapsed,
            mistakes: session.mistakes, hintsUsed: session.hintsUsed,
            isDaily: isDaily, todayEpochDay: Date().epochDayUTC)
        lastUnlockedAchievements = unlocked
        save()
        return unlocked
    }

    /// Bones earned by the most recent win (for the win screen).
    var lastWinBones: Int { state.lastWinBones }

    // MARK: - Hints (subscription -> free, then hint balance, then Bones)
    var hintBalance: Int { state.hintBalance }
    var canRevealHintFree: Bool { subscriptionActive || state.hintBalance > 0 }

    @discardableResult
    func useHintFromBalance() -> Bool {
        guard let session else { return false }
        if subscriptionActive { return session.useHint() }
        guard state.hintBalance > 0 else { return false }
        guard session.useHint() else { return false }
        state.hintBalance -= 1; save(); return true
    }

    @discardableResult
    func useHintWithBones() -> Bool {
        guard let session, state.bones >= Self.hintBonesCost else { return false }
        guard session.useHint() else { return false }
        state.bones -= Self.hintBonesCost; save(); return true
    }

    func grantHints(_ n: Int) { guard n > 0 else { return }; state.hintBalance += n; save() }

    @discardableResult
    func revealWithRewardedHint() -> Bool { grantHints(1); return useHintFromBalance() }

    // MARK: - Bones economy
    var bones: Int { state.bones }
    func addBones(_ n: Int) { guard n > 0 else { return }; state.bones += n; save() }
    @discardableResult
    func spendBones(_ n: Int) -> Bool { guard state.bones >= n else { return false }; state.bones -= n; save(); return true }

    // MARK: - Cosmetics (themes)
    var selectedThemeId: String { state.selectedTheme }
    func ownsTheme(_ id: String) -> Bool { state.ownedThemes.contains(id) }
    @discardableResult
    func buyTheme(_ theme: BoardTheme) -> Bool {
        if state.ownedThemes.contains(theme.id) { return true }
        guard theme.priceBones > 0, spendBones(theme.priceBones) else { return false }
        state.ownedThemes.insert(theme.id); save(); return true
    }
    func selectTheme(_ id: String) { guard state.ownedThemes.contains(id) else { return }; state.selectedTheme = id; save() }

    // MARK: - Event passes
    func ownsEventPass(_ id: String) -> Bool { state.ownedEventPasses.contains(id) }
    func unlockEventPass(productId: String) {
        guard let pass = EventPassCatalog.byProduct(productId) else { return }
        state.ownedEventPasses.insert(pass.id); state.ownedThemes.insert(pass.themeId); save()
    }
    @discardableResult
    func buyEventPassWithBones(_ pass: EventPass) -> Bool {
        if state.ownedEventPasses.contains(pass.id) { return true }
        guard spendBones(pass.bonesPrice) else { return false }
        state.ownedEventPasses.insert(pass.id); state.ownedThemes.insert(pass.themeId); save(); return true
    }
    func reconcileEventPasses(_ productIds: Set<String>) {
        for pid in productIds { if let pass = EventPassCatalog.byProduct(pid) {
            state.ownedEventPasses.insert(pass.id); state.ownedThemes.insert(pass.themeId)
        } }
        save()
    }

    // MARK: - Starter Pack
    func applyStarterPack() {
        state.bones += 600
        state.ownedThemes.insert("midnight")
        save()
    }

    // MARK: - Entitlements & settings
    func setRemoveAdsOwned(_ owned: Bool) { guard state.removeAdsOwned != owned else { return }; state.removeAdsOwned = owned; save() }
    func updateSettings(_ mutate: (inout GameState) -> Void) { mutate(&state); save() }
    func markOnboardingSeen() { state.hasSeenOnboarding = true; save() }

    func resetProgress() {
        var fresh = GameState()
        fresh.hasSeenOnboarding = true
        fresh.removeAdsOwned = state.removeAdsOwned
        fresh.ownedEventPasses = state.ownedEventPasses   // IAP-owned, keep
        for id in state.ownedEventPasses { if let pass = EventPassCatalog.pass(id) { fresh.ownedThemes.insert(pass.themeId) } }
        fresh.soundOn = state.soundOn; fresh.musicOn = state.musicOn; fresh.hapticsOn = state.hapticsOn
        fresh.highlightConflicts = state.highlightConflicts
        fresh.showTimer = state.showTimer; fresh.showMistakeCounter = state.showMistakeCounter
        fresh.colorblindLabels = state.colorblindLabels
        session = nil; state = fresh; save()
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
