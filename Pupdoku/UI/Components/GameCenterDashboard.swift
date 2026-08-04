import SwiftUI
import GameKit

/// SwiftUI bridge to Apple's native Game Center dashboard. Present it in a sheet
/// to show the leaderboards, achievements, or the full dashboard from inside the
/// app (the app already reports scores/achievements via `GameCenterManager`).
struct GameCenterView: UIViewControllerRepresentable {
    enum Panel { case dashboard, leaderboards, achievements }
    let panel: Panel
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator { dismiss() } }

    func makeUIViewController(context: Context) -> GKGameCenterViewController {
        let vc: GKGameCenterViewController
        switch panel {
        case .dashboard:    vc = GKGameCenterViewController(state: .dashboard)
        case .leaderboards: vc = GKGameCenterViewController(state: .leaderboards)
        case .achievements: vc = GKGameCenterViewController(state: .achievements)
        }
        vc.gameCenterDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ vc: GKGameCenterViewController, context: Context) {}

    final class Coordinator: NSObject, GKGameCenterControllerDelegate {
        let onFinish: () -> Void
        init(_ onFinish: @escaping () -> Void) { self.onFinish = onFinish }
        func gameCenterViewControllerDidFinish(_ vc: GKGameCenterViewController) { onFinish() }
    }
}
