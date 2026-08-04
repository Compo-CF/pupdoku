import SwiftUI

/// Top-level switch: first-run onboarding, then the home menu.
struct RootView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        HomeView()
            .fullScreenCover(isPresented: .constant(!store.state.hasSeenOnboarding)) {
                OnboardingView()
            }
    }
}
