import SwiftUI

/// The play screen: header (timer + puppies-placed), the board, and controls.
/// Interaction is tap-to-cycle (empty -> X -> puppy). No ads ever appear during a
/// puzzle; a sparse interstitial may show only after finishing one.
struct GameView: View {
    @Environment(GameStore.self) private var store
    @Environment(AdManager.self) private var ads
    @Environment(HapticsManager.self) private var haptics
    @Environment(SoundManager.self) private var sound
    @Environment(GameCenterManager.self) private var gameCenter
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview

    @State private var showWin = false
    @State private var showHintOptions = false
    @State private var showShop = false
    @State private var pendingReviewRequest = false

    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if let session = store.session { content(session) }
            else { Color.clear.onAppear { dismiss() } }
        }
    }

    @ViewBuilder
    private func content(_ session: QueensSession) -> some View {
        VStack(spacing: 14) {
            header(session)

            BoardView(session: session, appearance: appearance) { flat in
                tap(flat, in: session)
            }
            .padding(.horizontal, 16)

            rulesHint

            GameControlsBar(
                session: session,
                hintBalance: store.hintBalance,
                onUndo: { haptics.assist(); session.undo() },
                onHint: requestHint,
                onClear: { haptics.assist(); session.clearBoard() }
            )
            .padding(.horizontal, 16)

            Spacer(minLength: 0)
            // No banner over the board. Reviews accept bottom banners on menus but
            // dislike ads around active play, so Home carries the banner instead.
        }
        .pupBackground()
        .navigationBarBackButtonHidden(true)
        .onReceive(clock) { _ in if scenePhase == .active { session.tick() } }
        .onChange(of: session.status) { _, status in if status == .won { handleWin() } }
        .onChange(of: session.lastPlacedFlash) { _, v in
            if v != nil { DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { session.clearFlash() } }
        }
        .fullScreenCover(isPresented: $showWin, onDismiss: requestReviewIfPending) {
            WinView(
                spec: session.puzzle.spec,
                elapsed: session.elapsed,
                mistakes: session.mistakes,
                hintsUsed: session.hintsUsed,
                isDaily: store.isDaily,
                bestTime: store.state.bestTime(for: session.puzzle.spec),
                newlyUnlocked: store.lastUnlockedAchievements,
                onPlayAgain: { Task { await playAgain(session.puzzle.spec) } },
                onHome: { finishToHome() }
            )
        }
        .sheet(isPresented: $showShop) { ShopView() }
        .confirmationDialog("Out of hints", isPresented: $showHintOptions, titleVisibility: .visible) {
            Button(ads.rewardedReady ? "Watch an ad for a hint" : "Loading ad…") { watchRewardedHint() }
                .disabled(!ads.rewardedReady)
            Button("Get more hints") { showShop = true }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You are out of hints. Watch a short ad for one, or grab a hint pack.")
        }
    }

    @ViewBuilder
    private func header(_ session: QueensSession) -> some View {
        HStack {
            Button {
                store.stashCurrentGame(); dismiss()
            } label: {
                Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Palette.ink).frame(width: 40, height: 40)
                    .background(Palette.card, in: Circle()).shadow(color: .black.opacity(0.06), radius: 5, y: 2)
            }
            Spacer()
            VStack(spacing: 1) {
                Text(store.isDaily ? "Daily" : session.difficulty.subtitle)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                Text("\(session.difficulty.sizeLabel) · \(session.difficulty.displayName)")
                    .font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(Palette.inkSoft)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                if store.state.showTimer {
                    Text(formatClock(session.elapsed))
                        .font(.system(size: 16, weight: .heavy, design: .rounded).monospacedDigit())
                }
                Text("🐶 \(session.puppyCount)/\(session.n)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(Palette.inkSoft)
            }
            .frame(minWidth: 52, alignment: .trailing)
        }
        .foregroundStyle(Palette.ink).padding(.horizontal, 16).padding(.top, 8)
    }

    private var rulesHint: some View {
        Text("One puppy per row, column & color — none touching")
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(Palette.inkSoft)
            .padding(.horizontal, 16)
    }

    private var appearance: BoardAppearance {
        BoardAppearance(highlightConflicts: store.state.highlightConflicts,
                        colorblindLabels: store.state.colorblindLabels)
    }

    private func tap(_ flat: Int, in session: QueensSession) {
        let before = session.state(at: flat)
        session.cycle(flat)
        let after = session.state(at: flat)
        haptics.select()
        switch after {
        case .puppy: sound.place()
        case .marked: sound.note()
        case .empty: if before == .puppy { sound.note() }
        }
    }

    private func requestHint() {
        if store.useHintFromBalance() { haptics.assist(); sound.hint() }
        else { showHintOptions = true }
    }

    private func watchRewardedHint() {
        guard let root = UIApplication.topViewController() else { return }
        ads.showRewarded(from: root, onReward: { if store.revealWithRewardedHint() { haptics.assist(); sound.hint() } })
    }

    private func handleWin() {
        haptics.win(); sound.win()
        let unlocked = store.recordWinFromSession()
        Task {
            await gameCenter.report(state: store.state)
            await gameCenter.reportAchievements(store.state.unlockedAchievements)
        }
        if !unlocked.isEmpty { haptics.unlock(); sound.unlock() }
        if ReviewManager.shouldRequest(totalWins: store.state.totalWins) { pendingReviewRequest = true }
        showWin = true
    }

    private func requestReviewIfPending() {
        guard pendingReviewRequest else { return }
        pendingReviewRequest = false
        ReviewManager.recordRequested()
        requestReview()
    }

    private func playAgain(_ spec: PuzzleSpec) async {
        showWin = false
        maybeShowInterstitial()
        await store.startNewGame(spec: spec)
    }

    private func finishToHome() {
        showWin = false
        maybeShowInterstitial()
        store.abandonCurrentGame()
        dismiss()
    }

    private func maybeShowInterstitial() {
        guard let root = UIApplication.topViewController() else { return }
        ads.showInterstitialIfReady(from: root, totalWins: store.state.totalWins)
    }
}
