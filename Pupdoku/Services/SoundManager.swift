import Foundation
import Observation
import AVFoundation

/// Plays Pupdoku's original bundled sound effects via AVAudioPlayer. Each effect
/// keeps a small pool of players so rapid taps can overlap without cutting each
/// other off. Gated by the player's `soundOn` setting via `isEnabled`.
@MainActor
@Observable
final class SoundManager {
    var isEnabled: Bool = true

    private var pools: [String: [AVAudioPlayer]] = [:]
    private var cursor: [String: Int] = [:]

    private static let effects = ["select", "place", "note", "erase", "mistake", "hint", "win", "unlock"]
    private static let poolSize = 3

    init() { preload() }

    private func preload() {
        for name in Self.effects {
            guard let url = Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: "Audio")
                ?? Bundle.main.url(forResource: name, withExtension: "wav") else { continue }
            var pool: [AVAudioPlayer] = []
            for _ in 0..<Self.poolSize {
                if let p = try? AVAudioPlayer(contentsOf: url) { p.prepareToPlay(); pool.append(p) }
            }
            pools[name] = pool
        }
    }

    private func play(_ name: String, volume: Float = 1) {
        guard isEnabled, let pool = pools[name], !pool.isEmpty else { return }
        let i = (cursor[name] ?? 0) % pool.count
        cursor[name] = i + 1
        let p = pool[i]
        p.volume = volume
        p.currentTime = 0
        p.play()
    }

    func select()  { play("select", volume: 0.5) }
    func place()   { play("place",  volume: 0.9) }
    func note()    { play("note",   volume: 0.6) }
    func erase()   { play("erase",  volume: 0.6) }
    func mistake() { play("mistake", volume: 0.8) }
    func hint()    { play("hint",   volume: 0.8) }
    func win()     { play("win",    volume: 0.9) }
    func unlock()  { play("unlock", volume: 0.9) }
}
