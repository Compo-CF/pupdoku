import SwiftUI

/// Renders a single puppy breed illustration, sized to fit, with an optional
/// colorblind 2-letter code in the corner.
struct BreedTokenView: View {
    let breed: Breed
    var showCode: Bool = false

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack(alignment: .bottomTrailing) {
                Image(breed.assetName).resizable().scaledToFit().frame(width: side, height: side)
                if showCode {
                    Text(breed.code)
                        .font(.system(size: max(9, side * 0.24), weight: .heavy, design: .rounded))
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
