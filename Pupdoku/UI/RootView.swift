import SwiftUI

/// Top-level switch: an animated splash, then first-run onboarding, then the home
/// menu. The splash covers the brief startup work and fades to Home when done.
struct RootView: View {
    @Environment(GameStore.self) private var store
    @State private var showSplash = true

    var body: some View {
        ZStack {
            HomeView()
                // Hold onboarding until the splash has faded out.
                .fullScreenCover(isPresented: .constant(!store.state.hasSeenOnboarding && !showSplash)) {
                    OnboardingView()
                }

            if showSplash {
                SplashView {
                    withAnimation(.easeInOut(duration: 0.45)) { showSplash = false }
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }
}
