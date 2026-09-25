import Foundation

/// Solver for the "Find the Puppies" (Queens) constraint: exactly one puppy per
/// row, column, and region, with no two puppies adjacent (including diagonally).
///
/// Placing one puppy per row and requiring distinct columns means the only
/// adjacency that can ever occur is between *consecutive* rows — so it's enough
/// to check `abs(col - prevCol) >= 2` against the previous row.
enum QueensSolver {

    /// Counts solutions, short-circuiting at `limit`. Uniqueness = `== 1` with limit 2.
    static func countSolutions(n: Int, regionOf: [Int], limit: Int = 2) -> Int {
        var usedCols = [Bool](repeating: false, count: n)
        var usedRegions = [Bool](repeating: false, count: n)
        var count = 0
        func recurse(row: Int, prevCol: Int) -> Bool {
            if row == n { count += 1; return count >= limit }
            for col in 0..<n where !usedCols[col] {
                if row > 0 && abs(col - prevCol) < 2 { continue }
                let region = regionOf[row * n + col]
                if usedRegions[region] { continue }
                usedCols[col] = true; usedRegions[region] = true
                if recurse(row: row + 1, prevCol: col) { usedCols[col] = false; usedRegions[region] = false; return true }
                usedCols[col] = false; usedRegions[region] = false
            }
            return false
        }
        _ = recurse(row: 0, prevCol: -5)
        return count
    }

    /// Returns the per-row solution columns, or nil if unsolvable.
    static func solve(n: Int, regionOf: [Int]) -> [Int]? {
        var usedCols = [Bool](repeating: false, count: n)
        var usedRegions = [Bool](repeating: false, count: n)
        var cols = [Int](repeating: 0, count: n)
        func recurse(row: Int, prevCol: Int) -> Bool {
            if row == n { return true }
            for col in 0..<n where !usedCols[col] {
                if row > 0 && abs(col - prevCol) < 2 { continue }
                let region = regionOf[row * n + col]
                if usedRegions[region] { continue }
                usedCols[col] = true; usedRegions[region] = true; cols[row] = col
                if recurse(row: row + 1, prevCol: col) { return true }
                usedCols[col] = false; usedRegions[region] = false
            }
            return false
        }
        return recurse(row: 0, prevCol: -5) ? cols : nil
    }
}
