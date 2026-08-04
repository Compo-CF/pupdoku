import Foundation

/// An immutable, fully-specified puzzle: its spec, the seed that produced it,
/// the starting clue grid (`givens`), and the unique `solution`. Codable so an
/// in-progress game can be saved and resumed across launches.
struct Puzzle: Codable, Equatable {
    var spec: PuzzleSpec
    var seed: UInt64
    var givens: Grid
    var solution: Grid

    init(spec: PuzzleSpec, seed: UInt64, givens: Grid, solution: Grid) {
        self.spec = spec
        self.seed = seed
        self.givens = givens
        self.solution = solution
    }

    init(from result: SudokuGenerator.Result) {
        self.spec = result.spec
        self.seed = result.seed
        self.givens = result.puzzle
        self.solution = result.solution
    }

    /// Convenience: build a fresh random puzzle for a spec.
    static func random(spec: PuzzleSpec, rng: inout SeededRNG) -> Puzzle {
        let seed = rng.next()
        return generate(spec: spec, seed: seed)
    }

    static func generate(spec: PuzzleSpec, seed: UInt64) -> Puzzle {
        Puzzle(from: SudokuGenerator(spec: spec).generate(seed: seed))
    }

    var order: Int { spec.size.order }

    /// Flat indices whose value is fixed (part of the starting clues).
    var givenIndices: Set<Int> {
        var s = Set<Int>()
        for i in 0..<givens.cells.count where givens[i] != 0 { s.insert(i) }
        return s
    }
}
