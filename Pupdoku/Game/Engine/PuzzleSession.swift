import Foundation
import Observation

/// Per-difficulty play rules that don't belong on the pure `Difficulty` value.
extension Difficulty {
    /// Wrong placements allowed before the round is lost. `Puppy` is forgiving
    /// (kids / warm-up) so it never fails you.
    var mistakeLimit: Int {
        switch self {
        case .puppy:  return Int.max
        case .easy:   return 5
        case .medium: return 4
        case .hard:   return 3
        }
    }

    var hasMistakeLimit: Bool { mistakeLimit != Int.max }
}

/// The live state of one puzzle in play. Owns the working grid, pencil-note
/// marks, selection, undo history, mistake/hint counters and the clock. All
/// mutation goes through intent methods (`place`, `erase`, `toggleNote`, …) so
/// the view stays declarative and the rules live in one place.
@MainActor
@Observable
final class PuzzleSession {

    enum Status: Equatable { case playing, won, lost }

    let puzzle: Puzzle
    private(set) var working: Grid
    private(set) var notes: [Int: Set<Int>] = [:]

    var selected: Int?
    var isNotesMode: Bool = false
    /// When true, placing a breed clears that breed from peer notes (a friendly
    /// assist). Mirrors the `autoRemoveNotes` setting; set by `GameStore`.
    var respectsAutoNotes: Bool = true

    private(set) var mistakes: Int = 0
    private(set) var hintsUsed: Int = 0
    private(set) var status: Status = .playing
    private(set) var elapsed: TimeInterval = 0
    private(set) var isNewMistakeFlash: Int? // flat index that just went wrong, for a shake

    /// Set of flat indices currently in a rules conflict (recomputed on change).
    private(set) var conflicts: Set<Int> = []

    private let givenIndices: Set<Int>

    // Undo history: a stack of reversible snapshots (value + notes for one cell).
    private struct Move { let flat: Int; let previousValue: Int; let previousNotes: Set<Int> }
    private var history: [Move] = []

    var order: Int { puzzle.order }
    var size: GridSize { puzzle.spec.size }
    var difficulty: Difficulty { puzzle.spec.difficulty }
    var mistakeLimit: Int { difficulty.mistakeLimit }
    var canUndo: Bool { !history.isEmpty }

    init(puzzle: Puzzle, resume: SavedProgress? = nil) {
        self.puzzle = puzzle
        self.givenIndices = puzzle.givenIndices
        if let resume {
            self.working = resume.working
            self.notes = resume.notes
            self.mistakes = resume.mistakes
            self.hintsUsed = resume.hintsUsed
            self.elapsed = resume.elapsed
        } else {
            self.working = puzzle.givens
        }
        recomputeConflicts()
        evaluateStatus()
    }

    // MARK: - Queries

    func isGiven(_ flat: Int) -> Bool { givenIndices.contains(flat) }
    func value(at flat: Int) -> Int { working[flat] }
    func notes(at flat: Int) -> Set<Int> { notes[flat] ?? [] }

    /// Count of a breed value already correctly/allowably placed — used to grey
    /// out a palette button once all N of that breed are on the board.
    func remainingCount(of value: Int) -> Int {
        let placed = working.cells.filter { $0 == value }.count
        return max(0, order - placed)
    }

    var isBoardFull: Bool { working.isFull }

    // MARK: - Intents

    func select(_ flat: Int) {
        selected = (selected == flat) ? nil : flat
    }

    /// Place a breed value (1...order) into the selected cell, or toggle a note
    /// if notes mode is on. Givens are immutable.
    ///
    /// A *correct* placement stays and is undoable. A *wrong* placement counts a
    /// mistake, flashes the wrong pup briefly, then auto-removes itself — so the
    /// player never has to reach for Undo to clear a bad guess. (Puppy difficulty
    /// still never fails; it just clears the wrong pup.)
    func place(_ value: Int) {
        guard status == .playing, let flat = selected, !isGiven(flat) else { return }
        guard (1...order).contains(value) else { return }

        if isNotesMode {
            toggleNote(value, at: flat)
            return
        }

        // Tapping the same value again clears the cell.
        if working[flat] == value {
            pushHistory(flat)
            working[flat] = 0
            clearNotes(at: flat)
            afterChange()
            return
        }

        let previous = working[flat]

        if value == puzzle.solution[flat] {
            pushHistory(flat)
            working[flat] = value
            clearNotes(at: flat)
            if respectsAutoNotes { prunePeerNotes(of: value, around: flat) }
            afterChange()
        } else {
            // Wrong: show it (so the player sees what they tried), count a mistake,
            // then auto-remove after a short beat. No undo entry — it self-clears.
            working[flat] = value
            clearNotes(at: flat)
            registerMistake(at: flat)
            recomputeConflicts()
            evaluateStatus()
            scheduleWrongRevert(flat: flat, wrongValue: value, restoreTo: previous)
        }
    }

    /// After a short delay, remove a wrong placement (unless the player has since
    /// changed that cell themselves).
    private func scheduleWrongRevert(flat: Int, wrongValue: Int, restoreTo previous: Int) {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard working[flat] == wrongValue else { return }
            working[flat] = previous
            recomputeConflicts()
        }
    }

    func erase() {
        guard status == .playing, let flat = selected, !isGiven(flat) else { return }
        guard working[flat] != 0 || !notes(at: flat).isEmpty else { return }
        pushHistory(flat)
        working[flat] = 0
        clearNotes(at: flat)
        afterChange()
    }

    func toggleNote(_ value: Int, at flat: Int) {
        guard working[flat] == 0 else { return } // no notes on filled cells
        pushHistory(flat)
        var set = notes[flat] ?? []
        if set.contains(value) { set.remove(value) } else { set.insert(value) }
        notes[flat] = set.isEmpty ? nil : set
    }

    func toggleNotesMode() { isNotesMode.toggle() }

    /// Reveal the correct value for the selected (or best) empty cell. Returns
    /// `false` if there was nothing to reveal. Counts a hint (billing/limits are
    /// enforced by the caller against the player's hint balance).
    @discardableResult
    func useHint() -> Bool {
        guard status == .playing else { return false }
        let flat: Int
        if let s = selected, !isGiven(s), working[s] != puzzle.solution[s] {
            flat = s
        } else if let firstWrongOrEmpty = firstUnsolvedCell() {
            flat = firstWrongOrEmpty
        } else {
            return false
        }
        pushHistory(flat)
        working[flat] = puzzle.solution[flat]
        clearNotes(at: flat)
        hintsUsed += 1
        selected = flat
        afterChange()
        return true
    }

    func undo() {
        guard let move = history.popLast() else { return }
        working[move.flat] = move.previousValue
        if move.previousNotes.isEmpty { notes[move.flat] = nil } else { notes[move.flat] = move.previousNotes }
        selected = move.flat
        recomputeConflicts()
        evaluateStatus()
    }

    /// Advance the clock (called ~1×/second by the view while playing).
    func tick(_ delta: TimeInterval = 1) {
        guard status == .playing else { return }
        elapsed += delta
    }

    func clearMistakeFlash() { isNewMistakeFlash = nil }

    // MARK: - Persistence bridge

    func snapshot() -> SavedProgress {
        SavedProgress(
            spec: puzzle.spec,
            seed: puzzle.seed,
            givens: puzzle.givens,
            solution: puzzle.solution,
            working: working,
            notes: notes,
            mistakes: mistakes,
            hintsUsed: hintsUsed,
            elapsed: elapsed
        )
    }

    // MARK: - Internals

    private func afterChange() {
        recomputeConflicts()
        evaluateStatus()
    }

    private func registerMistake(at flat: Int) {
        mistakes += 1
        isNewMistakeFlash = flat
        if difficulty.hasMistakeLimit && mistakes >= mistakeLimit {
            status = .lost
        }
    }

    private func evaluateStatus() {
        guard status == .playing else { return }
        if working.isFull && working == puzzle.solution {
            status = .won
        }
    }

    private func recomputeConflicts() {
        conflicts = working.conflictingIndices()
    }

    private func pushHistory(_ flat: Int) {
        history.append(Move(flat: flat, previousValue: working[flat], previousNotes: notes[flat] ?? []))
        if history.count > 200 { history.removeFirst(history.count - 200) }
    }

    private func clearNotes(at flat: Int) { notes[flat] = nil }

    private func prunePeerNotes(of value: Int, around flat: Int) {
        let row = flat / order, col = flat % order
        let boxR = (row / working.boxRows) * working.boxRows
        let boxC = (col / working.boxCols) * working.boxCols
        for i in notes.keys {
            let r = i / order, c = i % order
            let sameRow = r == row, sameCol = c == col
            let sameBox = (r >= boxR && r < boxR + working.boxRows) && (c >= boxC && c < boxC + working.boxCols)
            if sameRow || sameCol || sameBox, var set = notes[i], set.contains(value) {
                set.remove(value)
                notes[i] = set.isEmpty ? nil : set
            }
        }
    }

    private func firstUnsolvedCell() -> Int? {
        for i in 0..<working.cells.count where !isGiven(i) && working[i] != puzzle.solution[i] {
            return i
        }
        return nil
    }
}

/// Flat, Codable snapshot of an in-progress game so a player can quit mid-puzzle
/// and resume exactly where they left off.
struct SavedProgress: Codable, Equatable {
    var spec: PuzzleSpec
    var seed: UInt64
    var givens: Grid
    var solution: Grid
    var working: Grid
    var notes: [Int: Set<Int>]
    var mistakes: Int
    var hintsUsed: Int
    var elapsed: TimeInterval

    var puzzle: Puzzle { Puzzle(spec: spec, seed: seed, givens: givens, solution: solution) }
}
