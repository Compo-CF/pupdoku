import SwiftUI
import AppTrackingTransparency

/// Three-page welcome that teaches the "Find the Puppies" rules, then requests
/// App Tracking Transparency last (so no other modal suppresses it).
struct OnboardingView: View {
    @Environment(GameStore.self) private var store
    @State private var page = 0

    private let pages: [(emoji: String, title: String, body: String)] = [
        ("🐶", "Welcome to Pupdoku!",
         "Find the hidden puppies on a colored board. Tap a square to rule it out, tap again to place a puppy."),
        ("🎨", "One puppy per color",
         "Every row, every column, and every colored region holds exactly one puppy — and no two puppies may touch, even diagonally."),
        ("🦴", "Deduce, don't guess",
         "Mark the squares you have ruled out to zero in on where each puppy must go. Stuck? Use a hint or come back for the Daily Puzzle."),
    ]

    var body: some View {
        VStack {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    VStack(spacing: 20) {
                        Spacer()
                        Text(pages[i].emoji).font(.system(size: 90))
                        Text(pages[i].title)
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .multilineTextAlignment(.center).foregroundStyle(Palette.ink)
                        Text(pages[i].body)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.center).foregroundStyle(Palette.inkSoft)
                            .padding(.horizontal, 36)
                        Spacer()
                    }
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button(action: advance) {
                Text(page < pages.count - 1 ? "Next" : "Let's Play!")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(Palette.accent, in: Capsule()).foregroundStyle(.white)
            }
            .padding(.horizontal, 32).padding(.bottom, 24)
        }
        .pupBackground()
        .interactiveDismissDisabled()
    }

    private func advance() {
        if page < pages.count - 1 {
            withAnimation { page += 1 }
        } else {
            store.markOnboardingSeen()
            Task {
                if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
                    _ = await ATTrackingManager.requestTrackingAuthorization()
                }
            }
        }
    }
}
