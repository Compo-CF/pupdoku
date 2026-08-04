import Foundation

/// Generates puzzles with a *guaranteed unique* solution.
///
/// Pipeline:
///   1. Build a complete, valid solution grid with randomized backtracking.
///   2. Dig holes one cell at a time (in a seeded-shuffled order), keeping a
///      hole only if the puzzle still has exactly one solution.
///   3. Stop once the target clue count is reached or every cell has been tried.
///
/// The whole thing is driven by a `SeededRNG`, so a given (spec, seed) pair
/// always produces the identical board — that is what makes the Daily Puzzle
/// consistent across devices, and what makes generation unit-testable.
struct SudokuGenerator {

    struct Result {
        let puzzle: Grid      // board with holes (the playable start state)
        let solution: Grid    // the unique completed board
        let seed: UInt64
        let spec: PuzzleSpec
        let clues: Int
    }

    let spec: PuzzleSpec

    func generate(seed: UInt64) -> Result {
        var rng = SeededRNG(seed: seed)
        let solution = makeSolution(rng: &rng)
        let puzzle = dig(from: solution, target: spec.targetClues, rng: &rng)
        return Result(
            puzzle: puzzle,
            solution: solution,
            seed: seed,
            spec: spec,
            clues: puzzle.filledCount
        )
    }

    // MARK: - 1. Full solution

    private func makeSolution(rng: inout SeededRNG) -> Grid {
        var g = Grid(size: spec.size)
        _ = fill(&g, rng: &rng)
        return g
    }

    /// Randomized backtracking fill of an empty grid. Trying candidate values in
    /// a shuffled order is what makes every generated board different.
    private func fill(_ g: inout Grid, rng: inout SeededRNG) -> Bool {
        // Find first empty cell (row-major is fine here; the shuffle is on values).
        guard let flat = g.cells.firstIndex(of: 0) else { return true }
        let row = flat / g.order
        let col = flat % g.order
        var values = Array(1...g.order)
        values.shuffle(using: &rng)
        for v in values where g.isLegal(v, at: row, col) {
            g[row, col] = v
            if fill(&g, rng: &rng) { return true }
            g[row, col] = 0
        }
        return false
    }

    // MARK: - 2. Dig holes preserving uniqueness

    private func dig(from solution: Grid, target: Int, rng: inout SeededRNG) -> Grid {
        var puzzle = solution
        var order = Array(0..<solution.cells.count)
        order.shuffle(using: &rng)

        var clues = solution.cells.count
        for flat in order {
            if clues <= target { break }
            let saved = puzzle[flat]
            guard saved != 0 else { continue }
            puzzle[flat] = 0
            // Keep the hole only if the solution is still unique.
            if SudokuSolver.countSolutions(puzzle, limit: 2) == 1 {
                clues -= 1
            } else {
                puzzle[flat] = saved // restore — removing it created ambiguity
            }
        }
        return puzzle
    }
}
