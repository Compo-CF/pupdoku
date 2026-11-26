import Foundation

/// Decides *when* to ask for an App Store rating, so the prompt lands on a happy
/// beat (just after a win) but never nags. Gating rules, all local:
/// - Only at win-count milestones (6, 18, 40): natural, spaced-out moments.
///   (The first used to be win #2, which can come minutes after install.)
/// - Guideline 5.6.3 (Alchemica 1.2.1 was rejected on 2026-11-25 for asking during
///   onboarding): never on a fresh install or in the first session. So also the
///   2nd+ app launch and 2+ days since the first launch.
/// - At most once per app version.
/// - At least 90 days between prompts.
/// - Never in the same session as the tip reminder (see `didPromptThisSession`).
///
/// Apple independently caps `requestReview` to ~3 prompts per 365 days and may
/// silently ignore calls; this gating keeps *our* asks tasteful on top of that.
enum ReviewManager {
    private static let lastVersionKey = "pupdoku.review.lastVersion"
    private static let lastDateKey    = "pupdoku.review.lastDate"
    private static let firstLaunchKey = "pupdoku.review.firstLaunchAt"
    private static let launchesKey    = "pupdoku.review.launchCount"
    static let betweenDays: Double = 90
    static let minDaysSinceFirstLaunch: Double = 2
    static let minLaunches = 2
    static let milestones: Set<Int> = [6, 18, 40]

    /// Set once we've surfaced *any* prompt (review or tip) this launch, so the
    /// two never stack in one session.
    static var didPromptThisSession = false

    private static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    /// Call once per cold start. Existing players start their 2-day clock at the
    /// first launch of this build.
    static func recordLaunch(defaults d: UserDefaults = .standard) {
        if d.double(forKey: firstLaunchKey) == 0 {
            d.set(Date().timeIntervalSince1970, forKey: firstLaunchKey)
        }
        d.set(d.integer(forKey: launchesKey) + 1, forKey: launchesKey)
    }

    /// Pure rule, unit-tested. Every condition must hold.
    static func eligible(totalWins: Int, launches: Int, firstLaunchAt: Double,
                         lastVersion: String?, lastDate: Double,
                         version: String, now: Double) -> Bool {
        guard milestones.contains(totalWins) else { return false }
        guard launches >= minLaunches, firstLaunchAt > 0,
              now - firstLaunchAt >= minDaysSinceFirstLaunch * 86400 else { return false }
        if lastVersion == version { return false } // once per version
        if lastDate > 0, now - lastDate < betweenDays * 86400 { return false }
        return true
    }

    /// Whether we should ask for a review now, given the player's total wins.
    static func shouldRequest(totalWins: Int) -> Bool {
        guard !didPromptThisSession else { return false }
        let d = UserDefaults.standard
        return eligible(totalWins: totalWins,
                        launches: d.integer(forKey: launchesKey),
                        firstLaunchAt: d.double(forKey: firstLaunchKey),
                        lastVersion: d.string(forKey: lastVersionKey),
                        lastDate: d.double(forKey: lastDateKey),
                        version: appVersion,
                        now: Date().timeIntervalSince1970)
    }

    /// Record that the prompt was requested (call right when you present it).
    static func recordRequested() {
        let d = UserDefaults.standard
        d.set(appVersion, forKey: lastVersionKey)
        d.set(Date().timeIntervalSince1970, forKey: lastDateKey)
        didPromptThisSession = true
    }
}
