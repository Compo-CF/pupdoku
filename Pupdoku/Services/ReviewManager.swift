import Foundation

/// Decides *when* to ask for an App Store rating, so the prompt lands on a happy
/// beat (just after a win) but never nags. Gating rules, all local:
/// - Only at win-count milestones (3, 12, 40) — natural, spaced-out moments.
/// - At most once per app version.
/// - At least 90 days between prompts.
/// - Never in the same session as the tip reminder (see `didPromptThisSession`).
///
/// Apple independently caps `requestReview` to ~3 prompts per 365 days and may
/// silently ignore calls; this gating keeps *our* asks tasteful on top of that.
enum ReviewManager {
    private static let lastVersionKey = "pupdoku.review.lastVersion"
    private static let lastDateKey    = "pupdoku.review.lastDate"
    private static let betweenDays: Double = 90
    private static let milestones: Set<Int> = [3, 12, 40]

    /// Set once we've surfaced *any* prompt (review or tip) this launch, so the
    /// two never stack in one session.
    static var didPromptThisSession = false

    private static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    /// Whether we should ask for a review now, given the player's total wins.
    static func shouldRequest(totalWins: Int) -> Bool {
        guard !didPromptThisSession, milestones.contains(totalWins) else { return false }
        let d = UserDefaults.standard
        if d.string(forKey: lastVersionKey) == appVersion { return false } // once per version
        let last = d.double(forKey: lastDateKey)
        if last > 0, Date().timeIntervalSince1970 - last < betweenDays * 86400 { return false }
        return true
    }

    /// Record that the prompt was requested (call right when you present it).
    static func recordRequested() {
        let d = UserDefaults.standard
        d.set(appVersion, forKey: lastVersionKey)
        d.set(Date().timeIntervalSince1970, forKey: lastDateKey)
        didPromptThisSession = true
    }
}
