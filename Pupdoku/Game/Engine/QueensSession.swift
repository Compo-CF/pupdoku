import Foundation
import Observation

/// The three states a cell can hold. Tapping cycles empty -> marked -> puppy -> empty.
enum CellState: Int, Codable { case empty = 0, marked = 1, puppy = 2 }

/// Live state of one "Find the Puppies" game. Owns the per-cell states, the
/// undo stack, conflict detection, the clock, and hint/mistake counters. All
/// mutation goes through intents so the view stays declarative.
@MainActor
@Observable
final class QueensSession {

    enum Status: Equatable { case playing, won }

    let puzzle: QueensPuzzle
    private(set) var states: [CellState]
    private(set) var conflicts: Set<Int> = []
    private(set) var status: Status = .playing
    private(set) var elapsed: TimeInterval = 0
    private(set) var mistakes: Int = 0
    private(set) var hintsUsed: Int = 0
    private(set) var lastPlacedFlash: Int?

    private var history: [[CellState]] = []

    var n: Int { puzzle.n }
    var difficulty: Difficulty { puzzle.difficulty }
    var canUndo: Bool { !history.isEmpty }
    var puppyCount: Int { states.reduce(0) { $0 + ($1 == .puppy ? 1 : 0) } }

    init(puzzle: QueensPuzzle, resume: QueensSavedProgress? = nil) {
        self.puzzle = puzzle
        if let resume, resume.states.count == puzzle.n * puzzle.n {
            self.states = resume.states
            self.elapsed = resume.elapsed
            self.mistakes = resume.mistakes
            self.hintsUsed = resume.hintsUsed
        } else {
            self.states = Array(repeating: .empty, count: puzzle.n * puzzle.n)
        }
        recompute()
    }

    // MARK: - Queries
    func state(at flat: Int) -> CellState { states[flat] }
    func region(at flat: Int) -> Int { puzzle.regionOf[flat] }

    // MARK: - Intents

    /// Cycle a cell: empty -> marked (ruled out) -> puppy -> empty.
    func cycle(_ flat: Int) {
        guard status == .playing else { return }
        pushHistory()
        switch states[flat] {
        case .empty:  states[flat] = .marked
        case .marked:
            states[flat] = .puppy
            if !puzzle.solutionIndices.contains(flat) { mistakes += 1 }
            lastPlacedFlash = flat
        case .puppy:  states[flat] = .empty
        }
        afterChange()
    }

    /// Reveal one correct puppy the player hasn't placed yet. Returns false if
    /// the board is already fully/ correctly populated.
    @discardableResult
    func useHint() -> Bool {
        guard status == .playing else { return false }
        for flat in puzzle.solutionIndices where states[flat] != .puppy {
            pushHistory()
            states[flat] = .puppy
            hintsUsed += 1
            lastPlacedFlash = flat
            afterChange()
            return true
        }
        return false
    }

    func undo() {
        guard let prev = history.popLast() else { return }
        states = prev
        recompute()
    }

    func clearBoard() {
        guard status == .playing, states.contains(where: { $0 != .empty }) else { return }
        pushHistory()
        states = Array(repeating: .empty, count: n * n)
        recompute()
    }

    func tick(_ delta: TimeInterval = 1) {
        guard status == .playing else { return }
        elapsed += delta
    }

    func clearFlash() { lastPlacedFlash = nil }

    // MARK: - Persistence
    func snapshot() -> QueensSavedProgress {
        QueensSavedProgress(puzzle: puzzle, states: states, elapsed: elapsed,
                            mistakes: mistakes, hintsUsed: hintsUsed)
    }

    // MARK: - Internals

    private func afterChange() { recompute(); evaluate() }

    private func recompute() {
        conflicts = computeConflicts()
    }

    private func evaluate() {
        guard status == .playing else { return }
        if puppyCount == n && conflicts.isEmpty { status = .won }
    }

    /// Puppies conflict if two share a row, column, or region, or touch (8-way).
    private func computeConflicts() -> Set<Int> {
        var puppies: [Int] = []
        for i in 0..<states.count where states[i] == .puppy { puppies.append(i) }
        var bad = Set<Int>()
        for a in 0..<puppies.count {
            for b in (a + 1)..<puppies.count {
                let p = puppies[a], q = puppies[b]
                let pr = p / n, pc = p % n, qr = q / n, qc = q % n
                let sameLine = pr == qr || pc == qc
                let sameRegion = puzzle.regionOf[p] == puzzle.regionOf[q]
                let touching = abs(pr - qr) <= 1 && abs(pc - qc) <= 1
                if sameLine || sameRegion || touching { bad.insert(p); bad.insert(q) }
            }
        }
        return bad
    }

    private func pushHistory() {
        history.append(states)
        if history.count > 100 { history.removeFirst(history.count - 100) }
    }
}

/// Flat, Codable snapshot of an in-progress game for resume.
struct QueensSavedProgress: Codable, Equatable {
    var puzzle: QueensPuzzle
    var states: [CellState]
    var elapsed: TimeInterval
    var mistakes: Int
    var hintsUsed: Int
}
