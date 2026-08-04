import UIKit
import Observation

/// Central haptic vocabulary. Each method names a specific in-game event so
/// call sites read like domain narration ("place", "win", "mistake") rather
/// than raw impact primitives. Gated by the player's `hapticsOn` setting, which
/// the caller passes through `isEnabled`.
@MainActor
@Observable
final class HapticsManager {
    var isEnabled: Bool = true

    private let lightImpact  = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact  = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidImpact  = UIImpactFeedbackGenerator(style: .rigid)
    private let softImpact   = UIImpactFeedbackGenerator(style: .soft)
    private let notification = UINotificationFeedbackGenerator()

    init() {
        [lightImpact, mediumImpact, heavyImpact, rigidImpact, softImpact].forEach { $0.prepare() }
        notification.prepare()
    }

    /// Selected a cell on the board.
    func select() { guard isEnabled else { return }; lightImpact.impactOccurred(intensity: 0.5) }

    /// Placed a breed into a cell (a legal, non-final move).
    func place() { guard isEnabled else { return }; mediumImpact.impactOccurred(intensity: 0.7) }

    /// Toggled a pencil note.
    func note() { guard isEnabled else { return }; softImpact.impactOccurred(intensity: 0.5) }

    /// Wrong breed — a mistake was recorded.
    func mistake() { guard isEnabled else { return }; notification.notificationOccurred(.error) }

    /// Completed a hint reveal or an undo.
    func assist() { guard isEnabled else { return }; rigidImpact.impactOccurred(intensity: 0.6) }

    /// Puzzle solved — the celebratory beat.
    func win() {
        guard isEnabled else { return }
        heavyImpact.impactOccurred(intensity: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) { [weak self] in
            self?.notification.notificationOccurred(.success)
        }
    }

    /// Ran out of mistakes — round lost.
    func lose() { guard isEnabled else { return }; notification.notificationOccurred(.warning) }

    /// Unlocked an achievement / new grid size.
    func unlock() {
        guard isEnabled else { return }
        rigidImpact.impactOccurred(intensity: 0.9)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            self?.notification.notificationOccurred(.success)
        }
    }
}
