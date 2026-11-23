import SwiftUI

/// The main menu: Continue, Play, Daily Puzzle, and access to Stats,
/// Achievements, Shop, and Settings. Owns the flow that starts a game and
/// presents `GameView`.
struct HomeView: View {
    @Environment(GameStore.self) private var store
    @Environment(IAPManager.self) private var iap
    @Environment(HapticsManager.self) private var haptics
    @Environment(DeepLinkRouter.self) private var router

    /// Single enum-driven sheet destination (more robust than several stacked
    /// `.sheet` modifiers, which can conflict on iOS).
    private enum Sheet: Int, Identifiable {
        case picker, stats, achievements, settings, shop, tip, challenge
        var id: Int { rawValue }
    }

    @State private var showGame = false
    @State private var activeSheet: Sheet?
    @State private var isStarting = false
    @State private var challengeForSheet: EventChallenge?

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

                    if let c = EventChallengeCatalog.featured(today: Date().epochDayUTC) {
                        challengeCard(c)
                    }
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 8)
                utilityRow
                    .padding(.horizontal, 24)

                if !iap.subscriptionActive {
                    paradeStrip
                        .padding(.horizontal, 24)
                }

                BannerAdSlot()
            }
            .pupBackground()
            .overlay(alignment: .topTrailing) { bonesPill.padding(.trailing, 20).padding(.top, 8) }

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
            case .challenge:
                if let c = challengeForSheet {
                    EventChallengeView(challenge: c) {
                        activeSheet = nil
                        start { await store.startDaily() }
                    }
                }
            }
        }
        .onChange(of: router.pendingRoute) { _, route in
            // Warm launch: the app was already open when the link was tapped.
            consumeDeepLink(route)
        }
        .onAppear {
            // Cold launch: a link set the route before Home appeared. Wait for
            // the splash to fade out before presenting the sheet.
            guard router.pendingRoute != nil else { return }
            Task {
                try? await Task.sleep(nanoseconds: 2_200_000_000)
                consumeDeepLink(router.pendingRoute)
            }
        }
    }

    /// Opens the Shop when a `pupdoku://event…` deep link arrives (e.g. the App
    /// Store Winter Pass In-App Event). Unknown or nil routes are ignored, and
    /// onboarding / an active game are never interrupted.
    private func consumeDeepLink(_ route: DeepLinkRouter.Route?) {
        guard let route else { return }
        router.pendingRoute = nil
        guard store.state.hasSeenOnboarding, !showGame else { return }
        switch route {
        case .shop:
            activeSheet = .shop
        case .challenge(let id):
            guard let c = EventChallengeCatalog.challenge(id) else { return }
            challengeForSheet = c
            activeSheet = .challenge
        }
    }

    private func challengeCard(_ c: EventChallenge) -> some View {
        let today = Date().epochDayUTC
        let progress = store.state.challengeProgress(c)
        let done = store.state.isChallengeComplete(c)
        let subtitle: String
        if c.isUpcoming(today: today) { subtitle = "Starts \(c.dateLabel.components(separatedBy: " - ").first ?? c.dateLabel) · solve \(c.goal) Dailies" }
        else if done { subtitle = "Complete! \(ThemeCatalog.theme(c.rewardThemeId).name) theme unlocked" }
        else { subtitle = "\(progress)/\(c.goal) Dailies · \(c.daysLeft(today: today)) days left" }
        return Button {
            haptics.select(); challengeForSheet = c; activeSheet = .challenge
        } label: {
            HStack(spacing: 14) {
                Text(c.emoji).font(.system(size: 26))
                VStack(alignment: .leading, spacing: 2) {
                    Text(c.name).font(.system(size: 16, weight: .heavy, design: .rounded))
                    Text(subtitle).font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.inkSoft)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(Palette.inkSoft)
            }
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 18).padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: "B79CF2").opacity(0.7), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Pieces

    private var bonesPill: some View {
        Button { haptics.select(); activeSheet = .shop } label: {
            Text("🦴 \(store.bones)")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, 13).padding(.vertical, 6)
                .background(Palette.card, in: Capsule())
                .shadow(color: .black.opacity(0.10), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var paradeStrip: some View {
        Button { haptics.select(); activeSheet = .shop } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("🎪 Parade Pass")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                    Text("Ad-free · unlimited hints")
                        .font(.system(size: 12, weight: .medium, design: .rounded)).opacity(0.92)
                }
                Spacer(minLength: 8)
                Text("Try it")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.paradeInk)
                    .padding(.horizontal, 16).padding(.vertical, 9)
                    .background(.white, in: Capsule())
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16).padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(Gradients.parade, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Palette.parade1.opacity(0.35), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var logo: some View {
        VStack(spacing: 6) {
            Image("breed_corgi").resizable().scaledToFit().frame(width: 104, height: 104)
                .shadow(color: Palette.brandShadow.opacity(0.35), radius: 12, y: 6)
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
            .background(filled ? AnyShapeStyle(Gradients.brand) : AnyShapeStyle(Palette.card),
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: filled ? Palette.brandShadow.opacity(0.4) : .black.opacity(0.05),
                    radius: filled ? 12 : 8, x: 0, y: filled ? 6 : 3)
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
