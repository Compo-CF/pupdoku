import Foundation
import Observation
import AudioToolbox

/// Lightweight sound effects using iOS system sound IDs so v1 ships with no
/// bundled audio assets. Each event maps to a short, tasteful system tone;
/// swap in custom `.caf` files later by loading them into `customSound(_:)`.
/// Gated by the player's `soundOn` setting via `isEnabled`.
@MainActor
@Observable
final class SoundManager {
    var isEnabled: Bool = true

    // System sound IDs (Apple's built-in UI sounds). Chosen to be short + soft.
    private let placeSound: SystemSoundID   = 1104  // key press "Tock"
    private let noteSound: SystemSoundID    = 1105  // key press modifier
    private let mistakeSound: SystemSoundID = 1053  // soft error
    private let winSound: SystemSoundID     = 1025  // fanfare-ish "Fanfare"
    private let unlockSound: SystemSoundID  = 1113  // "Begin Recording" chime

    func place()   { play(placeSound) }
    func note()    { play(noteSound) }
    func mistake() { play(mistakeSound) }
    func win()     { play(winSound) }
    func unlock()  { play(unlockSound) }

    private func play(_ id: SystemSoundID) {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(id)
    }
}
