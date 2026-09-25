import Foundation

/// A "Find the Puppies" board is N×N with N colored regions. Difficulty *is* the
/// board size — bigger boards mean more regions to deduce. This is the
/// progression axis: players start on 5×5 and unlock larger boards as they win.
enum Difficulty: Int, Codable, CaseIterable, Identifiable, Comparable {
    case puppy   = 0   // 5×5
    case easy    = 1   // 6×6
    case medium  = 2   // 7×7
    case hard    = 3   // 8×8
    case expert  = 4   // 9×9

    var id: Int { rawValue }

    /// Grid dimension and number of regions.
    var n: Int { [5, 6, 7, 8, 9][rawValue] }

    var displayName: String {
        switch self {
        case .puppy:  return "Puppy"
        case .easy:   return "Easy"
        case .medium: return "Medium"
        case .hard:   return "Hard"
        case .expert: return "Expert"
        }
    }

    var sizeLabel: String { "\(n) × \(n)" }

    var subtitle: String {
        switch self {
        case .puppy:  return "Puppy Pals"
        case .easy:   return "Little Litter"
        case .medium: return "Growing Pack"
        case .hard:   return "Big Pack"
        case .expert: return "Full Kennel"
        }
    }

    var emoji: String {
        switch self {
        case .puppy:  return "🐾"
        case .easy:   return "🦴"
        case .medium: return "🎾"
        case .hard:   return "🏆"
        case .expert: return "👑"
        }
    }

    /// The difficulty the player must clear to unlock this one (nil = always open).
    var previous: Difficulty? { rawValue == 0 ? nil : Difficulty(rawValue: rawValue - 1) }

    static func < (lhs: Difficulty, rhs: Difficulty) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// A fully-specified puzzle request.
struct PuzzleSpec: Codable, Hashable {
    var difficulty: Difficulty
    var n: Int { difficulty.n }
    var key: String { "\(difficulty.rawValue)" }
}
