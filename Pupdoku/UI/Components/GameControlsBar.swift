import SwiftUI

/// Undo / Hint / Clear controls beneath the board. Undo is always present
/// (removing it is exactly the kind of change players punish in reviews).
struct GameControlsBar: View {
    let session: QueensSession
    let hintBalance: Int
    let onUndo: () -> Void
    let onHint: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            button(system: "arrow.uturn.backward", label: "Undo", enabled: session.canUndo, action: onUndo)
            button(system: "lightbulb.fill", label: "Hint", badge: hintBalance, enabled: true, action: onHint)
            button(system: "trash", label: "Clear", enabled: session.puppyCount > 0 || session.canUndo, action: onClear)
        }
    }

    @ViewBuilder
    private func button(system: String, label: String, badge: Int? = nil,
                        enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: system).font(.system(size: 20, weight: .semibold)).frame(width: 30, height: 26)
                    if let badge {
                        Text("\(badge)")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(Palette.accentDeep, in: Capsule())
                            .offset(x: 10, y: -8)
                    }
                }
                Text(label).font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Palette.line, lineWidth: 1))
            .opacity(enabled ? 1 : 0.4)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}
