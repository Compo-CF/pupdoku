import SwiftUI

/// Undo / Erase / Notes / Hint control row shown above the breed palette.
struct GameControlsBar: View {
    let session: PuzzleSession
    let hintBalance: Int
    let onUndo: () -> Void
    let onErase: () -> Void
    let onToggleNotes: () -> Void
    let onHint: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            controlButton(system: "arrow.uturn.backward", label: "Undo",
                          enabled: session.canUndo, action: onUndo)
            controlButton(system: "eraser", label: "Erase",
                          enabled: session.selected != nil, action: onErase)
            controlButton(system: session.isNotesMode ? "pencil.circle.fill" : "pencil",
                          label: "Notes", active: session.isNotesMode,
                          enabled: true, action: onToggleNotes)
            controlButton(system: "lightbulb.fill", label: "Hint",
                          badge: hintBalance, enabled: true, action: onHint)
        }
    }

    @ViewBuilder
    private func controlButton(system: String, label: String,
                               badge: Int? = nil, active: Bool = false,
                               enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: system)
                        .font(.system(size: 20, weight: .semibold))
                        .frame(width: 30, height: 26)
                    if let badge, badge >= 0 {
                        Text("\(badge)")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(Palette.accentDeep, in: Capsule())
                            .offset(x: 10, y: -8)
                    }
                }
                Text(label)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(active ? Palette.accentDeep : Palette.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(active ? Palette.selected : Palette.card,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Palette.line, lineWidth: 1))
            .opacity(enabled ? 1 : 0.4)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}
