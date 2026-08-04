import SwiftUI
import AppTrackingTransparency

/// A short three-page welcome that teaches the one rule and the controls, then
/// requests App Tracking Transparency as the final step (matching Cosmica's
/// placement so the prompt isn't suppressed by a competing modal).
struct OnboardingView: View {
    @Environment(GameStore.self) private var store
    @State private var page = 0

    private let pages: [(emoji: String, title: String, body: String)] = [
        ("🐶", "Welcome to Pupdoku!",
         "It's sudoku — but with puppies. Fill the grid so every row, column, and box has one of each breed."),
        ("👆", "Tap a cell, pick a pup",
         "Tap an empty square, then tap a breed below to place it. Tap the same breed again to clear it."),
        ("🦴", "Notes, hints & the Daily",
         "Stuck? Use Notes to pencil in guesses, spend a Hint, or come back each day for a fresh Daily Puzzle and build a streak."),
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
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Palette.ink)
                        Text(pages[i].body)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Palette.inkSoft)
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
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Palette.accent, in: Capsule())
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
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
