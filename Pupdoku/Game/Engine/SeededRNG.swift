import Foundation

/// Deterministic, seedable random number generator (SplitMix64).
///
/// Used everywhere puzzle layout must be reproducible from a seed — most
/// importantly the Daily Puzzle, where every player on a given date must be
/// handed the exact same board. Seeding with the same `UInt64` always yields
/// the same stream, independent of platform or Swift's built-in RNG.
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // Avoid a zero state (SplitMix64 handles it, but keep it well-mixed).
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

extension SeededRNG {
    /// A stable seed for a given calendar day (UTC), so the Daily Puzzle is the
    /// same for everyone regardless of time zone offset within the date bucket.
    static func dailySeed(for date: Date, salt: UInt64 = 0xD06_5EED) -> UInt64 {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .current
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        let y = UInt64(comps.year ?? 2000)
        let m = UInt64(comps.month ?? 1)
        let d = UInt64(comps.day ?? 1)
        return (y &* 10_000 &+ m &* 100 &+ d) ^ salt
    }
}
