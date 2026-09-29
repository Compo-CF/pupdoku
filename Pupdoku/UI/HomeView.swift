import SwiftUI

/// The main menu: Continue, Play, Daily Puzzle, and access to Stats,
/// Achievements, Shop, and Settings. Owns the flow that starts a game and
/// presents `GameView`.
struct HomeView: View {
    @Environment(GameStore.self) private var store
    @Environment(IAPManager.self) private var iap
    @Environment(HapticsManager.self) private var haptics

    /// Single enum-driven sheet destination (more robust than several stacked
    /// `.sheet` modifiers, which can conflict on iOS).
    private enum Sheet: Int, Identifiable {
        case picker, stats, achievements, settings, shop, tip
        var id: Int { rawValue }
    }

    @State private var showGame = false
    @State private var activeSheet: Sheet?
    @State private var isStarting = false

    var body: some View {
        ZStack {
            VStack(spacing: 18) {
                Spacer(minLength: 8)
                logo
                Spacer(minLength: 8)

                VStack(spacing: 12) {
                    if store.hasSavedGame {
                        primaryButton(title: "Continue",
                                      subtitle: store.savedGameLabel,
                                      icon: "play.fill") {
                            haptics.select()
                            store.resumeSavedGame()
                            showGame = true
                        }
                    }

                    primaryButton(title: "Play", subtitle: "Pick a size & difficulty",
                                  icon: "square.grid.3x3.fill", filled: true) {
                        haptics.select(); activeSheet = .picker
                    }

                    dailyButton
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 8)
                utilityRow
                    .padding(.horizontal, 24)
                BannerAdSlot()
            }
            .pupBackground()

            if isStarting {
                Color.black.opacity(0.15).ignoresSafeArea()
                VStack(spacing: 12) {
                    ProgressView().controlSize(.large)
                    Text("Fetching a fresh board…")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Palette.ink)
                }
                .pupCard()
            }
        }
        .fullScreenCover(isPresented: $showGame, onDismiss: maybeSurfaceTip) { GameView() }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .picker:
                DifficultySelectView { spec in
                    activeSheet = nil
                    start { await store.startNewGame(spec: spec) }
                }
            case .stats:        StatsView()
            case .achievements: AchievementsView()
            case .settings:     SettingsView()
            case .shop:         ShopView()
            case .tip:          TipReminderView()
            }
        }
    }

    // MARK: - Pieces

    private var logo: some View {
        VStack(spacing: 6) {
            Image("breed_corgi").resizable().scaledToFit().frame(width: 96, height: 96)
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            Text("Pupdoku")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(Palette.ink)
            Text("Find the hidden puppies")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Palette.inkSoft)
        }
    }

    private var dailyButton: some View {
        Button {
            haptics.select()
            start { await store.startDaily() }
        } label: {
            HStack(spacing: 14) {
                Text("🦴").font(.system(size: 28))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Puzzle").font(.system(size: 18, weight: .heavy, design: .rounded))
                    Text(DailyPuzzle.label(for: Date())).font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.inkSoft)
                }
                Spacer()
                if store.state.dailyStreak > 0 {
                    VStack(spacing: 0) {
                        Text("🔥\(store.state.dailyStreak)").font(.system(size: 16, weight: .heavy, design: .rounded))
                        Text("streak").font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(Palette.inkSoft)
                    }
                }
            }
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 18).padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Palette.accent.opacity(0.4), lineWidth: 1.5))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }

    private var utilityRow: some View {
        HStack(spacing: 12) {
            utilityButton("chart.bar.fill", "Stats") { activeSheet = .stats }
            utilityButton("rosette", "Awards") { activeSheet = .achievements }
            utilityButton("cart.fill", "Shop") { activeSheet = .shop }
            utilityButton("gearshape.fill", "Settings") { activeSheet = .settings }
        }
    }

    // MARK: - Buttons

    @ViewBuilder
    private func primaryButton(title: String, subtitle: String?, icon: String,
                               filled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.system(size: 22, weight: .bold))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 20, weight: .heavy, design: .rounded))
                    if let subtitle {
                        Text(subtitle).font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(filled ? .white.opacity(0.9) : Palette.inkSoft)
                    }
                }
                Spacer()
            }
            .foregroundStyle(filled ? .white : Palette.ink)
            .padding(.horizontal, 20).padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .background(filled ? AnyShapeStyle(Palette.accent) : AnyShapeStyle(Palette.card),
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(filled ? 0.12 : 0.05), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func utilityButton(_ icon: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: { haptics.select(); action() }) {
            VStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 20, weight: .semibold))
                Text(label).font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 5, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Flow

    private func start(_ work: @escaping () async -> Void) {
        isStarting = true
        Task {
            await work()
            isStarting = false
            if store.session != nil { showGame = true }
        }
    }

    private func maybeSurfaceTip() {
        // After a game, occasionally surface the gentle tip reminder — but never
        // in the same session as the App Store review prompt.
        guard !ReviewManager.didPromptThisSession else { return }
        if iap.tipReminderEligible {
            iap.recordTipPromptShown()
            ReviewManager.didPromptThisSession = true
            activeSheet = .tip
        }
    }
}
