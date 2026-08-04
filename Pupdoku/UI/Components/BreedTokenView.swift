import SwiftUI

/// Renders a single puppy breed illustration, sized to fit. Optionally overlays
/// the 2-letter colorblind code in the corner when that accessibility setting
/// is on.
struct BreedTokenView: View {
    let breed: Breed
    var showCode: Bool = false

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack(alignment: .bottomTrailing) {
                Image(breed.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: side, height: side)
                if showCode {
                    Text(breed.code)
                        .font(.system(size: max(9, side * 0.22), weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4).padding(.vertical, 1)
                        .background(Palette.ink.opacity(0.75), in: Capsule())
                        .padding(2)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

/// A note (pencil-mark) grid drawn inside an empty cell: tiny dots/labels for
/// each candidate breed the player has jotted.
struct NoteGridView: View {
    let notes: Set<Int>
    let order: Int
    var colorblind: Bool = false

    private var columns: Int { order <= 4 ? 2 : 3 }

    var body: some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 0), count: columns)
        LazyVGrid(columns: cols, spacing: 0) {
            ForEach(1...order, id: \.self) { v in
                Group {
                    if notes.contains(v), let breed = BreedCatalog.breed(v) {
                        if colorblind {
                            Text(breed.code)
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .foregroundStyle(Palette.inkSoft)
                        } else {
                            Circle().fill(Color(hex: breed.hex))
                                .frame(width: 6, height: 6)
                        }
                    } else {
                        Color.clear.frame(width: 6, height: 6)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(3)
    }
}
