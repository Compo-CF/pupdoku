import SwiftUI

struct BoardAppearance {
    var highlightConflicts: Bool
    var colorblindLabels: Bool
    var regionColors: [Color] = []
    var costumeId: String? = nil
    /// Region fill from the active theme, falling back to the default palette.
    func color(_ i: Int) -> Color {
        regionColors.isEmpty ? Palette.region(i) : regionColors[i % regionColors.count]
    }
}

/// One cell of the board. Filled with its region color (from the active theme);
/// shows an X when ruled out, or the region puppy (with any event costume) when
/// placed — red ring when conflicting. Tapping cycles the state.
struct CellView: View {
    let session: QueensSession
    let flat: Int
    let appearance: BoardAppearance
    let onTap: () -> Void

    private var state: CellState { session.state(at: flat) }
    private var regionIndex: Int { session.region(at: flat) }
    private var isConflict: Bool { appearance.highlightConflicts && session.conflicts.contains(flat) }
    private var isFlash: Bool { session.lastPlacedFlash == flat }

    var body: some View {
        ZStack {
            Rectangle().fill(appearance.color(regionIndex))

            switch state {
            case .empty:
                EmptyView()
            case .marked:
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(Palette.ink.opacity(0.45))
            case .puppy:
                BreedTokenView(breed: BreedCatalog.breed(forRegion: regionIndex),
                               showCode: appearance.colorblindLabels,
                               costume: appearance.costumeId)
                    .padding(2)
                    .overlay(
                        isConflict
                        ? RoundedRectangle(cornerRadius: 6).stroke(Palette.danger, lineWidth: 2.5).padding(1)
                        : nil
                    )
                    .scaleEffect(isFlash ? 1.12 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.5), value: isFlash)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}
