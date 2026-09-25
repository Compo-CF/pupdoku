import Foundation

/// Generates "Find the Puppies" boards with a guaranteed-unique solution.
///
/// Pipeline (all driven by a `SeededRNG` so a given (spec, seed) reproduces the
/// exact board — this is what makes the Daily Puzzle fair and the whole thing
/// unit-testable):
///   1. Backtrack a random valid puppy placement: a column permutation whose
///      consecutive rows differ by >= 2 (one per row/col, none touching).
///   2. Seed one region per puppy, then grow regions outward — repeatedly assign
///      a random unassigned cell that is orthogonally adjacent to an already
///      assigned cell — until the whole board is partitioned into N contiguous
///      regions, one puppy each.
///   3. Accept only if the puzzle now has exactly one solution; otherwise regrow
///      the regions (and, after enough tries, reseed the placement).
struct QueensGenerator {

    struct Result {
        let n: Int
        let regionOf: [Int]
        let solutionCols: [Int]
        let seed: UInt64
        let spec: PuzzleSpec
    }

    let spec: PuzzleSpec
    var n: Int { spec.n }

    func generate(seed: UInt64) -> Result {
        var rng = SeededRNG(seed: seed)
        var attempts = 0
        while true {
            attempts += 1
            let placement = makePlacement(rng: &rng)
            // Try a few region layouts per placement before reseeding.
            for _ in 0..<12 {
                let regions = growRegions(solution: placement, rng: &rng)
                if QueensSolver.countSolutions(n: n, regionOf: regions, limit: 2) == 1 {
                    return Result(n: n, regionOf: regions, solutionCols: placement,
                                  seed: seed, spec: spec)
                }
            }
            // Safety valve: extremely unlikely, but never loop forever.
            if attempts > 200 {
                let regions = growRegions(solution: placement, rng: &rng)
                return Result(n: n, regionOf: regions, solutionCols: placement,
                              seed: seed, spec: spec)
            }
        }
    }

    // MARK: - 1. Valid placement (one per row/col, consecutive rows differ by >= 2)

    private func makePlacement(rng: inout SeededRNG) -> [Int] {
        var cols = [Int](repeating: -1, count: n)
        var used = [Bool](repeating: false, count: n)
        func recurse(_ row: Int) -> Bool {
            if row == n { return true }
            var candidates = Array(0..<n).filter { !used[$0] }
            if row > 0 { candidates = candidates.filter { abs($0 - cols[row - 1]) >= 2 } }
            candidates.shuffle(using: &rng)
            for c in candidates {
                cols[row] = c; used[c] = true
                if recurse(row + 1) { return true }
                used[c] = false; cols[row] = -1
            }
            return false
        }
        _ = recurse(0)
        return cols
    }

    // MARK: - 2. Grow contiguous regions from each puppy

    private func growRegions(solution: [Int], rng: inout SeededRNG) -> [Int] {
        var regionOf = [Int](repeating: -1, count: n * n)
        for row in 0..<n { regionOf[row * n + solution[row]] = row }  // seed region == row id

        var unassigned = n * n - n
        while unassigned > 0 {
            // Collect every (emptyCell, neighborRegion) pairing available right now.
            var frontier: [(cell: Int, region: Int)] = []
            for cell in 0..<(n * n) where regionOf[cell] == -1 {
                let r = cell / n, c = cell % n
                for (dr, dc) in [(-1, 0), (1, 0), (0, -1), (0, 1)] {
                    let nr = r + dr, nc = c + dc
                    guard nr >= 0, nr < n, nc >= 0, nc < n else { continue }
                    let region = regionOf[nr * n + nc]
                    if region != -1 { frontier.append((cell, region)) }
                }
            }
            guard !frontier.isEmpty else { break }
            let pick = frontier[Int(rng.next() % UInt64(frontier.count))]
            regionOf[pick.cell] = pick.region
            unassigned -= 1
        }
        return regionOf
    }
}
