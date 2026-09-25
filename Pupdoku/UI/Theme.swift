import SwiftUI

extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let r, g, b, a: Double
        switch s.count {
        case 8:
            r = Double((v >> 24) & 0xFF) / 255; g = Double((v >> 16) & 0xFF) / 255
            b = Double((v >> 8) & 0xFF) / 255;  a = Double(v & 0xFF) / 255
        default:
            r = Double((v >> 16) & 0xFF) / 255; g = Double((v >> 8) & 0xFF) / 255
            b = Double(v & 0xFF) / 255;         a = 1
        }
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

enum Palette {
    static let accent      = Color(hex: "F2A65A")
    static let accentDeep  = Color(hex: "E8933F")
    static let bgTop       = Color(hex: "FFF7EC")
    static let bgBottom    = Color(hex: "FBE7CE")
    static let card        = Color.white
    static let ink         = Color(hex: "3D3328")
    static let inkSoft     = Color(hex: "8A7C6B")
    static let line        = Color(hex: "D9C7AE")
    static let lineBold    = Color(hex: "6E5B44")   // region divider / outer frame
    static let danger      = Color(hex: "E5604D")
    static let success     = Color(hex: "5FA463")

    /// Up to 9 light region fills — chosen for hue separation so adjacent regions
    /// read apart, and light enough that the ❌ mark and puppy art sit clearly on top.
    static let regions: [Color] = [
        Color(hex: "F6C9A8"), Color(hex: "A8D8EA"), Color(hex: "C7E9B0"),
        Color(hex: "F7B7C6"), Color(hex: "F9E1A8"), Color(hex: "C9B8E8"),
        Color(hex: "A8E6CF"), Color(hex: "FFD3B6"), Color(hex: "D6C3A5"),
    ]

    static func region(_ i: Int) -> Color { regions[i % regions.count] }
}

extension View {
    func pupBackground() -> some View {
        background(
            LinearGradient(colors: [Palette.bgTop, Palette.bgBottom], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }
    func pupCard(padding: CGFloat = 16, radius: CGFloat = 20) -> some View {
        self.padding(padding)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

extension UIApplication {
    static func topViewController() -> UIViewController? {
        guard let scene = shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }),
              var top = window.rootViewController else { return nil }
        while let presented = top.presentedViewController { top = presented }
        return top
    }
}

func formatClock(_ t: TimeInterval) -> String {
    let total = Int(t)
    let h = total / 3600, m = (total % 3600) / 60, s = total % 60
    return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
}
