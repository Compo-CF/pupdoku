import Foundation

/// A puppy breed is Pupdoku's answer to a sudoku "digit". Value `1...9` maps to
/// a specific breed with its own illustration, accent color, and a short
/// colorblind-safe letter code. A puzzle of order N uses breeds `1...N`.
struct Breed: Identifiable, Equatable, Hashable {
    let value: Int          // 1...9
    let name: String        // "Corgi"
    let assetName: String   // image set in Assets.xcassets, e.g. "breed_corgi"
    let hex: String         // accent / tile background
    let code: String        // 2-letter colorblind fallback, e.g. "CO"
    let emoji: String       // used in share text & accessibility

    var id: Int { value }

    var accessibilityLabel: String { name }
}

enum BreedCatalog {
    /// The full ordered roster. Index i (0-based) is breed value i+1.
    /// Colors are chosen for maximum hue + lightness separation so all nine read
    /// apart at a glance — and the `code` gives a non-color fallback for the
    /// colorblind-labels accessibility setting.
    static let all: [Breed] = [
        Breed(value: 1, name: "Corgi",      assetName: "breed_corgi",      hex: "F2A65A", code: "Co", emoji: "🐕"),
        Breed(value: 2, name: "Husky",      assetName: "breed_husky",      hex: "6C8EBF", code: "Hu", emoji: "🐺"),
        Breed(value: 3, name: "Pug",        assetName: "breed_pug",        hex: "C9A36B", code: "Pu", emoji: "🐶"),
        Breed(value: 4, name: "Dalmatian",  assetName: "breed_dalmatian",  hex: "9AA0A6", code: "Da", emoji: "🐕‍🦺"),
        Breed(value: 5, name: "Golden",     assetName: "breed_golden",     hex: "F4C542", code: "Go", emoji: "🦮"),
        Breed(value: 6, name: "Shiba",      assetName: "breed_shiba",      hex: "E06B4A", code: "Sh", emoji: "🦊"),
        Breed(value: 7, name: "Beagle",     assetName: "breed_beagle",     hex: "A9744F", code: "Be", emoji: "🐾"),
        Breed(value: 8, name: "Poodle",     assetName: "breed_poodle",     hex: "E39AC0", code: "Po", emoji: "🐩"),
        Breed(value: 9, name: "Dachshund",  assetName: "breed_dachshund",  hex: "6E4B3A", code: "Dx", emoji: "🌭"),
    ]

    /// The breeds used by a puzzle of the given size (values 1...order).
    static func breeds(for size: GridSize) -> [Breed] {
        Array(all.prefix(size.order))
    }

    /// Look up a breed by its 1-based value. Returns `nil` for `0` (empty).
    static func breed(_ value: Int) -> Breed? {
        guard value >= 1, value <= all.count else { return nil }
        return all[value - 1]
    }
}
