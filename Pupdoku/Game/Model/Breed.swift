import Foundation

/// A puppy breed illustration. In "Find the Puppies", each colored region shows
/// its own breed when a puppy is placed there, so the board fills with a variety
/// of pups. `code` is the colorblind-safe 2-letter label.
struct Breed: Identifiable, Equatable, Hashable {
    let value: Int
    let name: String
    let assetName: String
    let hex: String
    let code: String
    let emoji: String
    var id: Int { value }
}

enum BreedCatalog {
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

    /// Breed shown for a given region index (0-based). Cycles through all 9.
    static func breed(forRegion index: Int) -> Breed { all[index % all.count] }
}
