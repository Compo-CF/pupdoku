import Foundation
import Observation
import AVFoundation

/// Plays the cozy background music loop. Seamlessly loops (`numberOfLoops = -1`)
/// at a gentle background volume, gated by the player's `musicOn` setting.
@MainActor
@Observable
final class MusicManager {
    var isEnabled: Bool = true

    private var player: AVAudioPlayer?

    init() {
        let url = Bundle.main.url(forResource: "music", withExtension: "wav", subdirectory: "Audio")
            ?? Bundle.main.url(forResource: "music", withExtension: "wav")
        if let url, let p = try? AVAudioPlayer(contentsOf: url) {
            p.numberOfLoops = -1
            p.volume = 0.45
            p.prepareToPlay()
            player = p
        }
    }

    /// Begin (or resume) playback if music is enabled.
    func start() {
        guard isEnabled, let player, !player.isPlaying else { return }
        player.play()
    }

    /// Pause without resetting position (e.g. when the app backgrounds).
    func pause() { player?.pause() }

    /// Apply the on/off setting — stop immediately when turned off, start when on.
    func setEnabled(_ on: Bool) {
        isEnabled = on
        if on { start() } else { player?.stop() }
    }
}
