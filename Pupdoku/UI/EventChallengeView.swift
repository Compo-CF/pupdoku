import SwiftUI

/// The New Year Pup Challenge sheet (App Store In-App Event destination for
/// `pupdoku://event/newyear`). Explains the challenge, shows progress as a row
/// of paw stamps, previews the reward (Confetti theme + party-hat pup), and
/// starts today's Daily Puzzle.
struct EventChallengeView: View {
    let challenge: EventChallenge
    let onPlayDaily: () -> Void

    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private var today: Int { Date().epochDayUTC }

    var body: some View {
        let progress = store.state.challengeProgress(challenge)
        let done = store.state.isChallengeComplete(challenge)
        let active = challenge.isActive(today: today)
        let solvedToday = Set(store.state.challengeDays?[challenge.id] ?? []).contains(today)
        let theme = ThemeCatalog.theme(challenge.rewardThemeId)

        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Text(challenge.emoji).font(.system(size: 60)).padding(.top, 8)
                    Text(challenge.name)
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(Palette.ink)
                    Text(challenge.dateLabel)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.inkSoft)
                    Text("Ring in the new year with the pack. Solve \(challenge.goal) Daily Puzzles during the challenge to earn the New Year Confetti board theme, party-hat puppies and \(challenge.rewardBones) Bones. Free for everyone, no pass needed.")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.inkSoft)
                        .padding(.horizontal, 24)

                    // Progress: one paw per Daily.
                    VStack(spacing: 10) {
                        Text(done ? "Challenge complete!" : "\(progress)/\(challenge.goal) Dailies")
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundStyle(Palette.ink)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 8) {
                            ForEach(0..<challenge.goal, id: \.self) { i in
                                Text(i < progress ? "🐾" : "○")
                                    .font(.system(size: 24))
                                    .foregroundStyle(Palette.line)
                                    .frame(height: 30)
                            }
                        }
                        if active && !done {
                            Text("\(challenge.daysLeft(today: today)) days left")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(Palette.inkSoft)
                        }
                    }
                    .pupCard()
                    .padding(.horizontal, 24)

                    // Reward preview.
                    VStack(spacing: 10) {
                        Text("Reward").font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundStyle(Palette.inkSoft)
                        HStack(spacing: 16) {
                            BreedTokenView(breed: BreedCatalog.all[0], costume: challenge.rewardCostumeId)
                                .frame(width: 72, height: 72)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 3), spacing: 3) {
                                ForEach(0..<9, id: \.self) { i in
                                    RoundedRectangle(cornerRadius: 4).fill(theme.color(i)).frame(height: 20)
                                }
                            }
                            .frame(width: 96)
                        }
                        Text("\(theme.name) theme · party hats · 🦴 \(challenge.rewardBones)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Palette.ink)
                    }
                    .pupCard()
                    .padding(.horizontal, 24)

                    if active && !done && !solvedToday {
                        Button(action: onPlayDaily) {
                            Text("Play today's Daily")
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(Gradients.brand, in: Capsule())
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)
                    } else if active && !done {
                        Text("Today's Daily is in! Come back tomorrow for the next one.")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Palette.inkSoft).multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    } else if challenge.isUpcoming(today: today) {
                        Text("The challenge opens \(challenge.dateLabel.components(separatedBy: " - ").first ?? challenge.dateLabel). Dailies you solve from then on count.")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Palette.inkSoft).multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 24)
            }
            .pupBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }
}
