import Foundation

/// A square Latin-square-with-boxes grid (i.e. a sudoku board of variable order).
/// Values are `1...order`; `0` means empty. Stored row-major in a flat array so
/// it is cheap to copy and `Codable` for saves.
struct Grid: Codable, Equatable {
    let order: Int
    let boxRows: Int
    let boxCols: Int
    private(set) var cells: [Int]

    init(size: GridSize) {
        self.order = size.order
        self.boxRows = size.boxRows
        self.boxCols = size.boxCols
        self.cells = Array(repeating: 0, count: size.cellCount)
    }

    init(order: Int, boxRows: Int, boxCols: Int, cells: [Int]) {
        self.order = order
        self.boxRows = boxRows
        self.boxCols = boxCols
        self.cells = cells
    }

    // MARK: - Indexing

    @inline(__always) func index(_ row: Int, _ col: Int) -> Int { row * order + col }

    subscript(row: Int, col: Int) -> Int {
        get { cells[index(row, col)] }
        set { cells[index(row, col)] = newValue }
    }

    subscript(flat: Int) -> Int {
        get { cells[flat] }
        set { cells[flat] = newValue }
    }

    var isFull: Bool { !cells.contains(0) }

    var filledCount: Int { cells.reduce(0) { $0 + ($1 != 0 ? 1 : 0) } }

    // MARK: - Legality

    /// Whether placing `value` at (row, col) violates no row / column / box
    /// constraint. Ignores the cell's own current contents.
    func isLegal(_ value: Int, at row: Int, _ col: Int) -> Bool {
        guard value != 0 else { return true }
        // Row & column.
        for i in 0..<order {
            if i != col, self[row, i] == value { return false }
            if i != row, self[i, col] == value { return false }
        }
        // Box.
        let boxR = (row / boxRows) * boxRows
        let boxC = (col / boxCols) * boxCols
        for r in boxR..<(boxR + boxRows) {
            for c in boxC..<(boxC + boxCols) {
                if (r != row || c != col), self[r, c] == value { return false }
            }
        }
        return true
    }

    /// All flat indices that currently hold a value conflicting with another
    /// cell in the same row, column, or box. Used to paint mistakes red.
    func conflictingIndices() -> Set<Int> {
        var conflicts = Set<Int>()
        for row in 0..<order {
            for col in 0..<order {
                let v = self[row, col]
                guard v != 0 else { continue }
                // Temporarily treat this cell as empty and test legality.
                if !isLegalIgnoringSelf(v, at: row, col) {
                    conflicts.insert(index(row, col))
                }
            }
        }
        return conflicts
    }

    private func isLegalIgnoringSelf(_ value: Int, at row: Int, _ col: Int) -> Bool {
        isLegal(value, at: row, col)
    }

    /// True when the grid is completely filled and legal — i.e. solved.
    func isSolved() -> Bool {
        guard isFull else { return false }
        return conflictingIndices().isEmpty
    }
}
