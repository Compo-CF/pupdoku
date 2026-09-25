import SwiftUI

/// Preferences, purchases entry points, legal links, and progress reset.
struct SettingsView: View {
    @Environment(GameStore.self) private var store
    @Environment(IAPManager.self) private var iap
    @Environment(GameCenterManager.self) private var gameCenter
    @Environment(\.dismiss) private var dismiss

    @State private var showResetConfirm = false
    @State private var showShop = false
    @State private var showGameCenter = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Feel") {
                    toggle("Music", \.musicOn)
                    toggle("Sound effects", \.soundOn)
                    toggle("Haptics", \.hapticsOn)
                }
                Section("Board") {
                    toggle("Show timer", \.showTimer)
                    toggle("Show mistake counter", \.showMistakeCounter)
                    toggle("Highlight conflicts", \.highlightConflicts)
                    toggle("Colorblind puppy labels", \.colorblindLabels)
                }
                if gameCenter.isAuthenticated {
                    Section("Game Center") {
                        Button {
                            showGameCenter = true
                        } label: {
                            Label("Leaderboards & Achievements", systemImage: "gamecontroller.fill")
                        }
                    }
                }
                Section("Store") {
                    Button {
                        if iap.removeAdsOwned { } else { showShop = true }
                    } label: {
                        HStack {
                            Label("Remove Ads", systemImage: "nosign")
                            Spacer()
                            Text(iap.removeAdsOwned ? "Owned" : (iap.displayPrice(for: IAPManager.removeAdsProductId) ?? "Store"))
                                .foregroundStyle(Palette.inkSoft)
                        }
                    }
                    .disabled(iap.removeAdsOwned)
                    Button("Hint packs & tips") { showShop = true }
                    Button("Restore purchases") { Task { await iap.restore() } }
                }
                Section("About") {
                    NavigationLink("Privacy Policy") { PrivacyPolicyView() }
                    NavigationLink("Terms of Service") { TermsOfServiceView() }
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion).foregroundStyle(Palette.inkSoft)
                    }
                }
                Section {
                    Button("Reset progress", role: .destructive) { showResetConfirm = true }
                }
            }
            .scrollContentBackground(.hidden)
            .pupBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
            .sheet(isPresented: $showShop) { ShopView() }
            .fullScreenCover(isPresented: $showGameCenter) {
                GameCenterView(panel: .dashboard).ignoresSafeArea()
            }
            .confirmationDialog("Reset all progress?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Reset everything", role: .destructive) { store.resetProgress() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears your wins, streaks, best times, and achievements on this device. Purchases are not affected.")
            }
        }
    }

    private func toggle(_ label: String, _ keyPath: WritableKeyPath<GameState, Bool>) -> some View {
        Toggle(label, isOn: Binding(
            get: { store.state[keyPath: keyPath] },
            set: { v in store.updateSettings { $0[keyPath: keyPath] = v } }
        ))
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}
