import SwiftUI

/// Size + difficulty picker. Sizes unlock progressively; locked ones show how
/// many wins remain. Selecting a difficulty starts the game via `onStart`.
struct DifficultySelectView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let onStart: (PuzzleSpec) -> Void

    @State private var size: GridSize = .four

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    sizePicker
                    difficultyList
                }
                .padding(20)
            }
            .pupBackground()
            .navigationTitle("New Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear { size = defaultUnlockedSize }
        }
    }

    private var defaultUnlockedSize: GridSize {
        if store.state.isUnlocked(.nine) { return .nine }
        if store.state.isUnlocked(.six) { return .six }
        return .four
    }

    private var sizePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Board Size").font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(Palette.inkSoft)
            HStack(spacing: 10) {
                ForEach(GridSize.allCases) { s in
                    sizeChip(s)
                }
            }
        }
    }

    @ViewBuilder
    private func sizeChip(_ s: GridSize) -> some View {
        let unlocked = store.state.isUnlocked(s)
        let selected = size == s
        Button {
            guard unlocked else { return }
            size = s
        } label: {
            VStack(spacing: 4) {
                Text(s.displayName).font(.system(size: 17, weight: .heavy, design: .rounded))
                if unlocked {
                    Text(s.subtitle).font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(selected ? .white.opacity(0.9) : Palette.inkSoft)
                } else {
                    Label("\(store.state.winsUntilUnlock(s)) wins", systemImage: "lock.fill")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                }
            }
            .foregroundStyle(selected ? .white : (unlocked ? Palette.ink : Palette.inkSoft))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(selected ? AnyShapeStyle(Palette.accent) : AnyShapeStyle(Palette.card),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.line, lineWidth: selected ? 0 : 1))
            .opacity(unlocked ? 1 : 0.55)
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
    }

    private var difficultyList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Difficulty").font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(Palette.inkSoft)
            ForEach(Difficulty.allCases) { d in
                let spec = PuzzleSpec(size: size, difficulty: d)
                Button {
                    onStart(spec)
                } label: {
                    HStack(spacing: 14) {
                        Text(d.emoji).font(.system(size: 26))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(d.displayName).font(.system(size: 18, weight: .heavy, design: .rounded))
                            Text(detail(for: spec)).font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(Palette.inkSoft)
                        }
                        Spacer()
                        if let best = store.state.bestTime(for: spec) {
                            VStack(alignment: .trailing, spacing: 0) {
                                Text(formatClock(best)).font(.system(size: 13, weight: .heavy, design: .rounded).monospacedDigit())
                                Text("best").font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(Palette.inkSoft)
                            }
                        }
                        Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(Palette.inkSoft)
                    }
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, 16).padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(Palette.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.04), radius: 5, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func detail(for spec: PuzzleSpec) -> String {
        let clues = spec.targetClues
        if spec.difficulty.hasMistakeLimit {
            return "\(clues) clues · \(spec.difficulty.mistakeLimit) mistakes allowed"
        }
        return "\(clues) clues · relaxed, no fail"
    }
}
