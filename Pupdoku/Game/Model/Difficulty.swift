import Foundation

/// The grid dimensions of a puzzle. Each maps to a box (sub-region) shape:
/// - `.four`  → 4×4 grid, 2×2 boxes, 4 breeds
/// - `.six`   → 6×6 grid, 2×3 boxes, 6 breeds
/// - `.nine`  → 9×9 grid, 3×3 boxes, 9 breeds
///
/// This is the *progression axis*: players start on 4×4 and unlock the larger
/// sizes as they win puzzles (see `GameState.isUnlocked`).
enum GridSize: Int, Codable, CaseIterable, Identifiable, Comparable {
    case four = 4
    case six  = 6
    case nine = 9

    var id: Int { rawValue }

    /// Number of cells per row/column and the count of distinct breeds used.
    var order: Int { rawValue }

    /// Box height (rows) and width (columns). Product must equal `order`.
    var boxRows: Int {
        switch self {
        case .four: return 2
        case .six:  return 2
        case .nine: return 3
        }
    }

    var boxCols: Int {
        switch self {
        case .four: return 2
        case .six:  return 3
        case .nine: return 3
        }
    }

    var cellCount: Int { order * order }

    var displayName: String {
        switch self {
        case .four: return "4 × 4"
        case .six:  return "6 × 6"
        case .nine: return "9 × 9"
        }
    }

    var subtitle: String {
        switch self {
        case .four: return "Puppy Pals"
        case .six:  return "Little Litter"
        case .nine: return "Full Pack"
        }
    }

    static func < (lhs: GridSize, rhs: GridSize) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// How hard a puzzle of a given size plays. Controls how many clues are removed
/// (more removed = harder) and the mistake / hint budget offered.
enum Difficulty: Int, Codable, CaseIterable, Identifiable {
    case puppy   = 0   // easiest — lots of clues
    case easy    = 1
    case medium  = 2
    case hard    = 3

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .puppy:  return "Puppy"
        case .easy:   return "Easy"
        case .medium: return "Medium"
        case .hard:   return "Hard"
        }
    }

    var emoji: String {
        switch self {
        case .puppy:  return "🐾"
        case .easy:   return "🦴"
        case .medium: return "🎾"
        case .hard:   return "🏆"
        }
    }

    /// Fraction of cells to leave *filled* as starting clues. The generator digs
    /// holes down toward this ratio while preserving a unique solution, so the
    /// realized clue count can end up slightly higher for the largest grids.
    var clueRatio: Double {
        switch self {
        case .puppy:  return 0.62
        case .easy:   return 0.52
        case .medium: return 0.42
        case .hard:   return 0.34
        }
    }
}

/// A fully-specified puzzle request: size + hardness. Uniquely determines the
/// generator's target clue count.
struct PuzzleSpec: Codable, Hashable {
    var size: GridSize
    var difficulty: Difficulty

    /// Target number of starting clues for this spec.
    var targetClues: Int {
        max(size.order, Int((Double(size.cellCount) * size.difficultyClueRatio(difficulty)).rounded()))
    }
}

private extension GridSize {
    /// Small per-size floor adjustment so 9×9 Hard stays humane and 4×4 stays
    /// solvable-by-a-kid. Keeps the ratio curve from producing degenerate boards.
    func difficultyClueRatio(_ d: Difficulty) -> Double {
        switch self {
        case .four: return max(d.clueRatio, 0.44)   // never fewer than ~7 clues
        case .six:  return max(d.clueRatio, 0.36)
        case .nine: return d.clueRatio
        }
    }
}
