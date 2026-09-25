import Foundation

/// An immutable "Find the Puppies" puzzle: an N×N board split into N contiguous
/// colored regions, with a guaranteed-unique solution placing one puppy per row,
/// column, and region such that no two puppies touch (including diagonally).
///
/// `regionOf` is row-major, length n*n, each value a region id in 0..<n.
/// `solutionCols[row]` is the column of the puppy in that row.
struct QueensPuzzle: Codable, Equatable {
    var difficulty: Difficulty
    var seed: UInt64
    var n: Int
    var regionOf: [Int]
    var solutionCols: [Int]

    init(difficulty: Difficulty, seed: UInt64, n: Int, regionOf: [Int], solutionCols: [Int]) {
        self.difficulty = difficulty
        self.seed = seed
        self.n = n
        self.regionOf = regionOf
        self.solutionCols = solutionCols
    }

    init(from result: QueensGenerator.Result) {
        self.difficulty = result.spec.difficulty
        self.seed = result.seed
        self.n = result.n
        self.regionOf = result.regionOf
        self.solutionCols = result.solutionCols
    }

    static func generate(spec: PuzzleSpec, seed: UInt64) -> QueensPuzzle {
        QueensPuzzle(from: QueensGenerator(spec: spec).generate(seed: seed))
    }

    @inline(__always) func index(_ row: Int, _ col: Int) -> Int { row * n + col }
    func region(at row: Int, _ col: Int) -> Int { regionOf[index(row, col)] }

    /// Flat indices that hold a puppy in the solution.
    var solutionIndices: Set<Int> {
        var s = Set<Int>()
        for row in 0..<n { s.insert(index(row, solutionCols[row])) }
        return s
    }

    var spec: PuzzleSpec { PuzzleSpec(difficulty: difficulty) }
}
