import SwiftUI

/// The play screen: header (timer + mistakes), the board, controls, breed
/// palette, and a banner. Drives the per-second clock and reacts to win/loss.
struct GameView: View {
    @Environment(GameStore.self) private var store
    @Environment(AdManager.self) private var ads
    @Environment(HapticsManager.self) private var haptics
    @Environment(SoundManager.self) private var sound
    @Environment(GameCenterManager.self) private var gameCenter
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview

    private enum Outcome: Int, Identifiable { case won, lost; var id: Int { rawValue } }
    @State private var outcome: Outcome?
    @State private var showHintOptions = false
    @State private var showShop = false
    @State private var pendingReviewRequest = false

    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if let session = store.session {
                content(session)
            } else {
                Color.clear.onAppear { dismiss() }
            }
        }
    }

    @ViewBuilder
    private func content(_ session: PuzzleSession) -> some View {
        VStack(spacing: 12) {
            header(session)

            BoardView(session: session, appearance: appearance) { flat in
                haptics.select()
                session.select(flat)
            }
            .padding(.horizontal, 12)

            GameControlsBar(
                session: session,
                hintBalance: store.hintBalance,
                onUndo: { haptics.assist(); session.undo() },
                onErase: { session.erase() },
                onToggleNotes: { haptics.note(); session.toggleNotesMode() },
                onHint: requestHint
            )
            .padding(.horizontal, 12)

            BreedPaletteView(session: session, colorblind: store.state.colorblindLabels) { value in
                place(value, in: session)
            }
            .padding(.horizontal, 12)

            Spacer(minLength: 0)
            BannerAdSlot()
        }
        .pupBackground()
        .navigationBarBackButtonHidden(true)
        .onReceive(clock) { _ in
            if scenePhase == .active { session.tick() }
        }
        .onChange(of: session.status) { _, status in
            switch status {
            case .won:  handleWin()
            case .lost: handleLoss()
            case .playing: break
            }
        }
        .onChange(of: session.mistakes) { _, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { session.clearMistakeFlash() }
        }
        .fullScreenCover(item: $outcome, onDismiss: requestReviewIfPending) { result in
            switch result {
            case .won:
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
            case .lost:
                LoseView(
                    onRetry: { Task { await playAgain(session.puzzle.spec) } },
                    onHome: { finishToHome() }
                )
            }
        }
        .sheet(isPresented: $showShop) { ShopView() }
        .confirmationDialog("Out of hints", isPresented: $showHintOptions, titleVisibility: .visible) {
            Button(ads.rewardedReady ? "Watch an ad for a hint" : "Loading ad…") { watchRewardedHint() }
                .disabled(!ads.rewardedReady)
            Button("Get more hints") { showShop = true }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You're out of hints. Watch a short ad for one, or grab a hint pack.")
        }
    }

    // MARK: - Header

    @ViewBuilder
    private func header(_ session: PuzzleSession) -> some View {
        HStack {
            Button {
                store.stashCurrentGame()
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Palette.ink)
                    .frame(width: 40, height: 40)
                    .background(Palette.card, in: Circle())
                    .shadow(color: .black.opacity(0.06), radius: 5, y: 2)
            }
            Spacer()
            VStack(spacing: 1) {
                Text(store.isDaily ? "Daily" : session.size.subtitle)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                Text("\(session.size.displayName) · \(session.difficulty.displayName)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.inkSoft)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                if store.state.showTimer {
                    Text(formatClock(session.elapsed))
                        .font(.system(size: 16, weight: .heavy, design: .rounded).monospacedDigit())
                }
                if store.state.showMistakeCounter && session.difficulty.hasMistakeLimit {
                    Text("✕ \(session.mistakes)/\(session.mistakeLimit)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(session.mistakes >= session.mistakeLimit ? Palette.danger : Palette.inkSoft)
                }
            }
            .frame(minWidth: 44, alignment: .trailing)
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var appearance: BoardAppearance {
        BoardAppearance(
            highlightPeers: store.state.highlightPeers,
            highlightSameBreed: store.state.highlightSameBreed,
            colorblindLabels: store.state.colorblindLabels
        )
    }

    // MARK: - Actions

    private func place(_ value: Int, in session: PuzzleSession) {
        let before = session.mistakes
        session.place(value)
        if session.isNotesMode {
            sound.note()
        } else if session.mistakes > before {
            haptics.mistake(); sound.mistake()
        } else {
            haptics.place(); sound.place()
        }
    }

    private func requestHint() {
        if store.useHintFromBalance() {
            haptics.assist()
        } else {
            showHintOptions = true
        }
    }

    private func watchRewardedHint() {
        guard let root = UIApplication.topViewController() else { return }
        ads.showRewarded(from: root, onReward: {
            if store.revealWithRewardedHint() { haptics.assist() }
        })
    }

    private func handleWin() {
        haptics.win(); sound.win()
        let unlocked = store.recordWinFromSession()
        Task {
            await gameCenter.report(state: store.state)
            await gameCenter.reportAchievements(store.state.unlockedAchievements)
        }
        if !unlocked.isEmpty { haptics.unlock(); sound.unlock() }
        // Flag a rating prompt for milestone wins; it fires after the win screen
        // is dismissed so it never covers the celebration.
        if ReviewManager.shouldRequest(totalWins: store.state.totalWins) {
            pendingReviewRequest = true
        }
        outcome = .won
    }

    /// Called when the win/lose cover is dismissed. Asks for a review if this win
    /// hit a milestone (and records it so it won't ask again this version).
    private func requestReviewIfPending() {
        guard pendingReviewRequest else { return }
        pendingReviewRequest = false
        ReviewManager.recordRequested()
        requestReview()
    }

    private func handleLoss() {
        haptics.lose()
        store.recordLossFromSession()
        outcome = .lost
    }

    private func playAgain(_ spec: PuzzleSpec) async {
        outcome = nil
        maybeShowInterstitial()
        await store.startNewGame(spec: spec)
    }

    private func finishToHome() {
        outcome = nil
        maybeShowInterstitial()
        store.abandonCurrentGame()
        dismiss()
    }

    private func maybeShowInterstitial() {
        guard let root = UIApplication.topViewController() else { return }
        ads.showInterstitialIfReady(from: root)
    }
}
