import SwiftUI

/// All achievements with locked / unlocked state and a progress summary.
struct AchievementsView: View {
    @Environment(GameStore.self) private var store
    @Environment(GameCenterManager.self) private var gameCenter
    @Environment(\.dismiss) private var dismiss

    @State private var showGameCenter = false

    private var unlocked: Set<String> { store.state.unlockedAchievements }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    header
                    ForEach(AchievementCatalog.all) { a in
                        row(a, earned: unlocked.contains(a.id))
                    }
                }
                .padding(20)
            }
            .pupBackground()
            .navigationTitle("Awards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                if gameCenter.isAuthenticated {
                    ToolbarItem(placement: .primaryAction) {
                        Button { showGameCenter = true } label: {
                            Image(systemName: "gamecontroller.fill")
                        }
                        .accessibilityLabel("Open in Game Center")
                    }
                }
            }
            .fullScreenCover(isPresented: $showGameCenter) {
                GameCenterView(panel: .achievements).ignoresSafeArea()
            }
        }
    }

    private var header: some View {
        let total = AchievementCatalog.all.count
        return VStack(spacing: 4) {
            Text("\(unlocked.count) / \(total)")
                .font(.system(size: 30, weight: .black, design: .rounded)).foregroundStyle(Palette.ink)
            Text("achievements unlocked")
                .font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(Palette.inkSoft)
        }
        .frame(maxWidth: .infinity).padding(.bottom, 4)
    }

    @ViewBuilder
    private func row(_ a: Achievement, earned: Bool) -> some View {
        HStack(spacing: 14) {
            Text(earned ? a.emoji : "🔒").font(.system(size: 30)).grayscale(earned ? 0 : 1).opacity(earned ? 1 : 0.6)
            VStack(alignment: .leading, spacing: 2) {
                Text(a.title).font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundStyle(Palette.ink)
                Text(a.detail).font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(Palette.inkSoft)
            }
            Spacer()
            if earned {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.success).font(.system(size: 20))
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .opacity(earned ? 1 : 0.7)
        .shadow(color: .black.opacity(0.04), radius: 5, y: 2)
    }
}
