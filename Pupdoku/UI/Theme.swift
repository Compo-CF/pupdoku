import SwiftUI

/// Central color + style vocabulary. Pupdoku runs in a single warm, playful
/// light palette (forced via `.preferredColorScheme(.light)` at the root) so the
/// board and puppy art always read against the same friendly cream backdrop.
extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let r, g, b, a: Double
        switch s.count {
        case 8:
            r = Double((v >> 24) & 0xFF) / 255
            g = Double((v >> 16) & 0xFF) / 255
            b = Double((v >> 8) & 0xFF) / 255
            a = Double(v & 0xFF) / 255
        default:
            r = Double((v >> 16) & 0xFF) / 255
            g = Double((v >> 8) & 0xFF) / 255
            b = Double(v & 0xFF) / 255
            a = 1
        }
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

enum Palette {
    static let accent      = Color(hex: "F2A65A")   // corgi orange
    static let accentDeep  = Color(hex: "E8933F")
    static let bgTop       = Color(hex: "FFF7EC")
    static let bgBottom    = Color(hex: "FBE7CE")
    static let card        = Color.white
    static let ink         = Color(hex: "3D3328")   // warm near-black text
    static let inkSoft     = Color(hex: "8A7C6B")
    static let line        = Color(hex: "D9C7AE")   // thin grid line
    static let lineBold    = Color(hex: "9E8A6E")    // box divider
    static let cellGiven   = Color(hex: "FDF3E4")
    static let cellEmpty   = Color.white
    static let selected    = Color(hex: "FBD9A6")
    static let peer        = Color(hex: "FBEFDC")
    static let sameBreed   = Color(hex: "F7E3C0")
    static let danger      = Color(hex: "E5604D")
    static let success     = Color(hex: "5FA463")
}

extension View {
    /// The standard warm gradient app background.
    func pupBackground() -> some View {
        background(
            LinearGradient(colors: [Palette.bgTop, Palette.bgBottom],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }

    /// A soft white rounded card.
    func pupCard(padding: CGFloat = 16, radius: CGFloat = 20) -> some View {
        self
            .padding(padding)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

extension UIApplication {
    /// The top-most view controller, for presenting AdMob ads and share sheets.
    static func topViewController() -> UIViewController? {
        guard let scene = shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }),
              var top = window.rootViewController
        else { return nil }
        while let presented = top.presentedViewController { top = presented }
        return top
    }
}

/// Formats a play-clock TimeInterval as m:ss (or h:mm:ss past an hour).
func formatClock(_ t: TimeInterval) -> String {
    let total = Int(t)
    let h = total / 3600, m = (total % 3600) / 60, s = total % 60
    return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
}
