import SwiftUI
import AppTrackingTransparency

@main
struct PupdokuApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    @State private var store: GameStore
    @State private var ads = AdManager()
    @State private var iap = IAPManager()
    @State private var haptics = HapticsManager()
    @State private var sound = SoundManager()
    @State private var music = MusicManager()
    @State private var gameCenter = GameCenterManager()
    @State private var cloud = CloudSync()

    init() {
        let persistence = (try? Persistence()) ?? Persistence.inMemory()
        let initial = persistence.load()
        _store = State(initialValue: GameStore(state: initial, persistence: persistence))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(ads)
                .environment(iap)
                .environment(haptics)
                .environment(sound)
                .environment(music)
                .environment(gameCenter)
                .preferredColorScheme(.light)
                .tint(Palette.accentDeep)
                .task {
                    // Sync feature toggles into the effect managers.
                    haptics.isEnabled = store.state.hapticsOn
                    sound.isEnabled = store.state.soundOn
                    music.isEnabled = store.state.musicOn
                    music.start()

                    store.applyLaunch()
                    await iap.start()
                    store.setRemoveAdsOwned(iap.removeAdsOwned)
                    store.subscriptionActive = iap.subscriptionActive
                    store.reconcileEventPasses(iap.restoredEventPasses)
                    ads.configure(removeAdsOwned: iap.removeAdsOwned || iap.subscriptionActive)
                    gameCenter.authenticate()
                    await syncFromCloudIfNeeded()
                    await gameCenter.report(state: store.state)
                    await gameCenter.reportAchievements(store.state.unlockedAchievements)

                    // Fallback ATT request for users who already dismissed
                    // onboarding on an older build. New installs get it in
                    // OnboardingView.finish(). Delay so no modal is presenting.
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    await requestTrackingPermissionIfNeeded()
                }
                .onChange(of: iap.removeAdsOwned) { _, owned in
                    ads.configure(removeAdsOwned: owned || iap.subscriptionActive)
                    store.setRemoveAdsOwned(owned)
                }
                .onChange(of: iap.subscriptionActive) { _, active in
                    store.subscriptionActive = active
                    ads.configure(removeAdsOwned: iap.removeAdsOwned || active)
                }
                .onChange(of: iap.pendingHintGrant) { _, grant in
                    guard grant > 0 else { return }
                    store.grantHints(grant); iap.pendingHintGrant = 0
                }
                .onChange(of: iap.pendingBonesGrant) { _, b in
                    guard b > 0 else { return }
                    store.addBones(b); iap.pendingBonesGrant = 0
                }
                .onChange(of: iap.pendingStarterPack) { _, flag in
                    guard flag else { return }
                    store.applyStarterPack(); iap.pendingStarterPack = false
                }
                .onChange(of: iap.pendingEventPassUnlock) { _, pid in
                    guard let pid else { return }
                    store.unlockEventPass(productId: pid); iap.pendingEventPassUnlock = nil
                }
                .onChange(of: iap.restoredEventPasses) { _, passes in
                    store.reconcileEventPasses(passes)
                }
                .onChange(of: store.state.hapticsOn) { _, on in haptics.isEnabled = on }
                .onChange(of: store.state.soundOn) { _, on in sound.isEnabled = on }
                .onChange(of: store.state.musicOn) { _, on in music.setEnabled(on) }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background, .inactive:
                music.pause()
                store.stashCurrentGame()
                store.save()
                let snapshot = store.state
                Task { try? await cloud.push(state: snapshot) }
                Task { await gameCenter.report(state: snapshot) }
            case .active:
                music.start()
            @unknown default:
                break
            }
        }
    }

    private func requestTrackingPermissionIfNeeded() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        _ = await ATTrackingManager.requestTrackingAuthorization()
    }

    private func syncFromCloudIfNeeded() async {
        guard let remote = try? await cloud.pull() else { return }
        let reconciled = await cloud.reconcile(local: store.state, remote: remote)
        if reconciled != store.state {
            store.replaceState(reconciled)
            haptics.isEnabled = store.state.hapticsOn
            sound.isEnabled = store.state.soundOn
        }
    }
}
