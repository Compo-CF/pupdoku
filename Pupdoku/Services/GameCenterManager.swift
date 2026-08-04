import Foundation
import Observation
import GameKit

/// Wraps Game Center authentication, leaderboard submission, and achievement
/// reporting. All identifiers must match what you configure in App Store
/// Connect (leaderboard IDs and achievement IDs — the latter reuse
/// `Achievement.id`).
@MainActor
@Observable
final class GameCenterManager {
    static let leaderboardTotalWins   = "pupdoku.total_wins"
    static let leaderboardDailyStreak = "pupdoku.daily_streak"
    static let leaderboardPerfectWins = "pupdoku.perfect_wins"

    private(set) var isAuthenticated = false

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            if let error {
                print("[GameCenter] Auth failed: \(error.localizedDescription)")
                self?.isAuthenticated = false
                return
            }
            if viewController == nil {
                self?.isAuthenticated = GKLocalPlayer.local.isAuthenticated
            }
        }
    }

    func report(state: GameState) async {
        guard isAuthenticated else { return }
        await submit(score: state.totalWins,          leaderboard: Self.leaderboardTotalWins)
        await submit(score: state.longestDailyStreak, leaderboard: Self.leaderboardDailyStreak)
        await submit(score: state.perfectWins,        leaderboard: Self.leaderboardPerfectWins)
    }

    /// Report already-unlocked achievements to Game Center (idempotent — GC
    /// ignores lower percentComplete). Called after a win and on launch sync.
    func reportAchievements(_ ids: some Sequence<String>) async {
        guard isAuthenticated else { return }
        let achievements = ids.map { id -> GKAchievement in
            let a = GKAchievement(identifier: id)
            a.percentComplete = 100
            a.showsCompletionBanner = true
            return a
        }
        guard !achievements.isEmpty else { return }
        do {
            try await GKAchievement.report(achievements)
        } catch {
            print("[GameCenter] Achievement report failed: \(error.localizedDescription)")
        }
    }

    private func submit(score: Int, leaderboard: String) async {
        do {
            try await GKLeaderboard.submitScore(
                score,
                context: 0,
                player: GKLocalPlayer.local,
                leaderboardIDs: [leaderboard]
            )
        } catch {
            print("[GameCenter] Submit failed for \(leaderboard): \(error.localizedDescription)")
        }
    }
}
