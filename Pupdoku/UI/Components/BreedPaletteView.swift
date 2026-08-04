import SwiftUI

/// The breed input bar. One button per breed used by the current puzzle; tapping
/// places (or notes) that breed into the selected cell. A breed dims once all N
/// of it are placed on the board.
struct BreedPaletteView: View {
    let session: PuzzleSession
    var colorblind: Bool
    let onPick: (Int) -> Void

    private var breeds: [Breed] { BreedCatalog.breeds(for: session.size) }

    // 4×4 → 4 across; 6×6 → 6; 9×9 → wrap into two rows via adaptive grid.
    private var columns: [GridItem] {
        let count = session.order <= 6 ? session.order : 5
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: count)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(breeds) { breed in
                let remaining = session.remainingCount(of: breed.value)
                Button {
                    onPick(breed.value)
                } label: {
                    VStack(spacing: 2) {
                        BreedTokenView(breed: breed, showCode: colorblind)
                            .frame(height: 42)
                        Text(remaining > 0 ? "\(remaining)" : "✓")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(remaining > 0 ? Palette.inkSoft : Palette.success)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Palette.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Palette.line, lineWidth: 1)
                    )
                    .opacity(remaining > 0 ? 1 : 0.4)
                }
                .buttonStyle(.plain)
                .disabled(remaining == 0 && !session.isNotesMode)
            }
        }
    }
}
