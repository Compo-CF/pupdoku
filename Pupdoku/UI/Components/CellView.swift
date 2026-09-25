import SwiftUI

struct BoardAppearance {
    var highlightConflicts: Bool
    var colorblindLabels: Bool
}

/// One cell of the board. Filled with its region color; shows an ❌ when ruled
/// out, or the region's puppy when placed (red ring when conflicting). Tapping
/// cycles the state.
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
            Rectangle().fill(Palette.region(regionIndex))

            switch state {
            case .empty:
                EmptyView()
            case .marked:
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(Palette.ink.opacity(0.45))
                    .scaleEffect(1.0)
            case .puppy:
                BreedTokenView(breed: BreedCatalog.breed(forRegion: regionIndex),
                               showCode: appearance.colorblindLabels)
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
