import SwiftUI

/// Visual + interaction preferences the board needs, bundled so cells don't
/// each reach into the store.
struct BoardAppearance {
    var highlightPeers: Bool
    var highlightSameBreed: Bool
    var colorblindLabels: Bool
}

/// One cell on the board. Reads the live `PuzzleSession` so it re-renders as the
/// player fills, notes, and makes mistakes.
struct CellView: View {
    let session: PuzzleSession
    let flat: Int
    let appearance: BoardAppearance
    let onTap: () -> Void

    private var order: Int { session.order }
    private var value: Int { session.value(at: flat) }
    private var isGiven: Bool { session.isGiven(flat) }
    private var isSelected: Bool { session.selected == flat }
    private var isConflict: Bool { session.conflicts.contains(flat) }
    private var isMistakeFlash: Bool { session.isNewMistakeFlash == flat }

    private var selectedValue: Int? {
        guard let s = session.selected else { return nil }
        let v = session.value(at: s)
        return v == 0 ? nil : v
    }

    private var isSameBreedAsSelection: Bool {
        guard appearance.highlightSameBreed, let sv = selectedValue, value != 0 else { return false }
        return value == sv
    }

    private var isPeerOfSelection: Bool {
        guard appearance.highlightPeers, let s = session.selected, s != flat else { return false }
        let r1 = flat / order, c1 = flat % order
        let r2 = s / order, c2 = s % order
        if r1 == r2 || c1 == c2 { return true }
        let br = session.working.boxRows, bc = session.working.boxCols
        return (r1 / br == r2 / br) && (c1 / bc == c2 / bc)
    }

    private var background: Color {
        if isSelected { return Palette.selected }
        if isSameBreedAsSelection { return Palette.sameBreed }
        if isPeerOfSelection { return Palette.peer }
        return isGiven ? Palette.cellGiven : Palette.cellEmpty
    }

    var body: some View {
        ZStack {
            Rectangle().fill(background)
            if value != 0, let breed = BreedCatalog.breed(value) {
                BreedTokenView(breed: breed, showCode: appearance.colorblindLabels)
                    .padding(2)
                    .opacity(isGiven ? 1.0 : 0.98)
                    .overlay(
                        isConflict
                        ? RoundedRectangle(cornerRadius: 6).stroke(Palette.danger, lineWidth: 2).padding(1)
                        : nil
                    )
            } else if !session.notes(at: flat).isEmpty {
                NoteGridView(notes: session.notes(at: flat), order: order,
                             colorblind: appearance.colorblindLabels)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .scaleEffect(isMistakeFlash ? 1.08 : 1.0)
        .animation(.spring(response: 0.22, dampingFraction: 0.5), value: isMistakeFlash)
    }
}
