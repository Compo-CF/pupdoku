import Foundation

/// Backtracking solver over a `Grid` of any order. Uses the
/// minimum-remaining-values (MRV) heuristic to pick the most-constrained empty
/// cell first, which keeps 9×9 solves fast enough to run on the main actor
/// during generation.
enum SudokuSolver {

    /// Returns a solved copy of `grid`, or `nil` if it has no solution.
    static func solve(_ grid: Grid) -> Grid? {
        var g = grid
        return solveInPlace(&g) ? g : nil
    }

    /// Counts solutions, short-circuiting as soon as `limit` is reached. The
    /// generator uses `countSolutions(_, limit: 2) == 1` as its uniqueness test.
    static func countSolutions(_ grid: Grid, limit: Int = 2) -> Int {
        var g = grid
        var count = 0
        _ = countInPlace(&g, count: &count, limit: limit)
        return count
    }

    // MARK: - Core

    @discardableResult
    private static func solveInPlace(_ g: inout Grid) -> Bool {
        guard let (row, col, candidates) = mostConstrainedCell(g) else {
            return true // no empty cell left → solved
        }
        if candidates.isEmpty { return false }
        for v in candidates {
            g[row, col] = v
            if solveInPlace(&g) { return true }
            g[row, col] = 0
        }
        return false
    }

    private static func countInPlace(_ g: inout Grid, count: inout Int, limit: Int) -> Bool {
        guard let (row, col, candidates) = mostConstrainedCell(g) else {
            count += 1
            return count >= limit // signal caller to stop
        }
        if candidates.isEmpty { return false }
        for v in candidates {
            g[row, col] = v
            let hitLimit = countInPlace(&g, count: &count, limit: limit)
            g[row, col] = 0
            if hitLimit { return true }
        }
        return false
    }

    /// Finds the empty cell with the fewest legal candidates. Returns `nil` when
    /// the grid is full. If any empty cell has zero candidates, returns it with
    /// an empty candidate set so the caller backtracks immediately.
    private static func mostConstrainedCell(_ g: Grid) -> (row: Int, col: Int, candidates: [Int])? {
        var best: (row: Int, col: Int, candidates: [Int])?
        for row in 0..<g.order {
            for col in 0..<g.order where g[row, col] == 0 {
                var candidates: [Int] = []
                candidates.reserveCapacity(g.order)
                for v in 1...g.order where g.isLegal(v, at: row, col) {
                    candidates.append(v)
                }
                if candidates.isEmpty { return (row, col, []) }
                if best == nil || candidates.count < best!.candidates.count {
                    best = (row, col, candidates)
                    if candidates.count == 1 { return best } // can't do better
                }
            }
        }
        return best
    }
}
