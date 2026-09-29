import SwiftUI

/// Cosmetics picker: preview, buy (with Bones), and select board themes. Event
/// themes (Spooky/Winter) are unlocked by their Event Pass in the Shop.
struct ThemesView: View {
    @Environment(GameStore.self) private var store
    @Environment(HapticsManager.self) private var haptics
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                HStack {
                    Text("🦴 \(store.bones)")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.ink)
                    Spacer()
                    Text("Bones").font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Palette.inkSoft)
                }
                .pupCard().padding(.horizontal, 20).padding(.top, 12)

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(ThemeCatalog.all) { theme in card(theme) }
                }
                .padding(20)
            }
            .pupBackground()
            .navigationTitle("Themes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }

    @ViewBuilder
    private func card(_ theme: BoardTheme) -> some View {
        let owned = store.ownsTheme(theme.id)
        let selected = store.selectedThemeId == theme.id
        let eventLocked = theme.eventPassId != nil && !owned
        VStack(spacing: 10) {
            swatch(theme)
            Text(theme.name).font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(Palette.ink)
            actionButton(theme, owned: owned, selected: selected, eventLocked: eventLocked)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(selected ? Palette.accent : Palette.line, lineWidth: selected ? 2.5 : 1))
        .shadow(color: .black.opacity(0.04), radius: 5, y: 2)
    }

    private func swatch(_ theme: BoardTheme) -> some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 3), count: 3)
        return LazyVGrid(columns: cols, spacing: 3) {
            ForEach(0..<9, id: \.self) { i in
                RoundedRectangle(cornerRadius: 4).fill(theme.color(i)).frame(height: 22)
            }
        }
    }

    @ViewBuilder
    private func actionButton(_ theme: BoardTheme, owned: Bool, selected: Bool, eventLocked: Bool) -> some View {
        if selected {
            label("Selected", bg: Palette.accent, fg: .white)
        } else if owned {
            Button { haptics.select(); store.selectTheme(theme.id) } label: { label("Select", bg: Palette.card, fg: Palette.ink, bordered: true) }
                .buttonStyle(.plain)
        } else if eventLocked {
            label("Event Pass", bg: Palette.card, fg: Palette.inkSoft, bordered: true)
        } else {
            Button {
                if store.buyTheme(theme) { haptics.unlock(); store.selectTheme(theme.id) } else { haptics.select() }
            } label: { label("\(theme.priceBones) 🦴", bg: Palette.accent, fg: .white) }
                .buttonStyle(.plain)
                .disabled(store.bones < theme.priceBones)
                .opacity(store.bones < theme.priceBones ? 0.5 : 1)
        }
    }

    private func label(_ t: String, bg: Color, fg: Color, bordered: Bool = false) -> some View {
        Text(t)
            .font(.system(size: 13, weight: .heavy, design: .rounded))
            .foregroundStyle(fg)
            .frame(maxWidth: .infinity).padding(.vertical, 9)
            .background(bg, in: Capsule())
            .overlay(bordered ? Capsule().stroke(Palette.line, lineWidth: 1) : nil)
    }
}
