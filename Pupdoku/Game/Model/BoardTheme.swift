import SwiftUI

/// A cosmetic board theme: a 9-color region palette (owned forever once unlocked).
/// Free "classic" is the default; others cost Bones; event themes unlock only with
/// their Event Pass.
struct BoardTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let priceBones: Int          // 0 = free / not directly purchasable
    let eventPassId: String?     // non-nil = unlocked only via that Event Pass
    let hexes: [String]          // 9 region fills

    var id_: String { id }
    var colors: [Color] { hexes.map { Color(hex: $0) } }
    func color(_ i: Int) -> Color { colors[i % colors.count] }
}

enum ThemeCatalog {
    static let all: [BoardTheme] = [
        BoardTheme(id: "classic", name: "Classic", priceBones: 0, eventPassId: nil, hexes: [
            "F6C9A8","A8D8EA","C7E9B0","F7B7C6","F9E1A8","C9B8E8","A8E6CF","FFD3B6","D6C3A5"]),
        BoardTheme(id: "midnight", name: "Midnight", priceBones: 500, eventPassId: nil, hexes: [
            "5B6BA8","4E8FA6","5AA574","B0668A","C6A24E","7A5FA6","4FA58C","C07A4E","6E6152"]),
        BoardTheme(id: "pastel", name: "Pastel Dream", priceBones: 500, eventPassId: nil, hexes: [
            "FBD3D8","D7E9FB","E4F5D0","FCE7C8","E9DBF7","D2F1EC","FBE0EF","E7EAF6","F3E6D0"]),
        BoardTheme(id: "neon", name: "Neon Pups", priceBones: 800, eventPassId: nil, hexes: [
            "FF7BAC","4DE1E6","B5FF5A","FFD23F","9B6BFF","4DFFB0","FF9F45","5AC8FF","FF6B6B"]),
        BoardTheme(id: "autumn", name: "Autumn Walk", priceBones: 500, eventPassId: nil, hexes: [
            "E8A15A","C97B4A","D9B36B","B5654A","E0C067","8C6D46","C08552","A7683F","D89A5B"]),
        BoardTheme(id: "spooky", name: "Spooky", priceBones: 0, eventPassId: "eventpass.spooky2026", hexes: [
            "6B4E9E","E58A3C","3E3A5C","8C5AA8","C0873C","5A4E7A","A05AC0","D06A2C","4A4460"]),
        BoardTheme(id: "winter", name: "Winter", priceBones: 0, eventPassId: "eventpass.winter2026", hexes: [
            "BFE3F5","E7F1FA","9FC8E8","D64F4F","CFE8F0","8FB8D8","EAF4FB","5FA0C8","D9EAF4"]),
    ]

    static func theme(_ id: String) -> BoardTheme { all.first { $0.id == id } ?? all[0] }
    /// Themes purchasable directly with Bones (excludes free + event-locked).
    static var buyableWithBones: [BoardTheme] { all.filter { $0.priceBones > 0 && $0.eventPassId == nil } }
}
