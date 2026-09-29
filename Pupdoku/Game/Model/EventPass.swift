import Foundation

/// A seasonal Event Pass: a non-consumable that unlocks a themed board palette,
/// costume puppy markers, and a themed Daily badge. Buyable via IAP or Bones.
struct EventPass: Identifiable, Equatable {
    let id: String               // short id, e.g. "eventpass.spooky2026"
    let productId: String        // full StoreKit id
    let name: String
    let emoji: String
    let themeId: String          // BoardTheme unlocked
    let costumeId: String        // costume overlay set id
    let bonesPrice: Int          // alternative unlock price in Bones

    var id_: String { id }
}

enum EventPassCatalog {
    static let all: [EventPass] = [
        EventPass(id: "eventpass.spooky2026",
                  productId: "com.centricfiber.pupdoku.eventpass.spooky2026",
                  name: "Spooky Pass 2026", emoji: "🎃",
                  themeId: "spooky", costumeId: "spooky", bonesPrice: 2000),
        EventPass(id: "eventpass.winter2026",
                  productId: "com.centricfiber.pupdoku.eventpass.winter2026",
                  name: "Winter Pass 2026", emoji: "❄️",
                  themeId: "winter", costumeId: "winter", bonesPrice: 2000),
    ]

    static func pass(_ id: String) -> EventPass? { all.first { $0.id == id } }
    static func byProduct(_ productId: String) -> EventPass? { all.first { $0.productId == productId } }
}
