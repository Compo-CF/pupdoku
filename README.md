# Pupdoku 🐶

Sudoku, but with puppies. A warm, family-friendly take on the classic — fill each
row, column, and box with one of each illustrated breed. Built for iOS in
SwiftUI, on the same stack as Cosmica.

## Features

- **Three grid sizes with progression** — start on 4×4 (Puppy Pals), unlock 6×6
  (Little Litter) and 9×9 (Full Pack) as you win.
- **Four difficulties** — Puppy (no-fail, kid-friendly), Easy, Medium, Hard,
  each with tuned clue counts and mistake budgets.
- **Guaranteed-unique puzzles** — a seeded generator digs holes while checking
  the solution stays unique, so every board is fair (and the Daily is identical
  for everyone).
- **Daily Puzzle + streaks** — one 9×9 per day (difficulty rotates by weekday),
  with fire-streak tracking.
- **9 custom illustrated breeds** — Corgi, Husky, Pug, Dalmatian, Golden, Shiba,
  Beagle, Poodle, Dachshund. Colorblind letter-code labels optional.
- **Assists** — pencil notes, auto-clear peer notes, hints (balance-based),
  undo, mistake highlighting, peer + matching-breed highlighting.
- **Full monetization** — AdMob banner + interstitial + rewarded ("watch for a
  hint"), Remove Ads IAP, hint-pack IAPs, and an opt-out tip jar.
- **Game Center** leaderboards (total wins, daily streak, perfect wins) and
  achievements.
- **CloudKit** private sync of progress across devices.

## Project layout

```
Pupdoku/
  App/         PupdokuApp, AppDelegate
  Game/
    Model/     Breed, Difficulty, Puzzle, GameState, Achievement, DailyPuzzle
    Engine/    SeededRNG, Grid, SudokuSolver, SudokuGenerator, PuzzleSession, GameStore
  Services/    Ad, IAP, GameCenter, CloudSync, Persistence, Haptics, Sound
  UI/          Root, Onboarding, Home, DifficultySelect, Game, Win, Stats,
               Achievements, Settings, Shop, TipReminder, Privacy, Terms
    Components/ BoardView, CellView, BreedTokenView, BreedPaletteView,
                GameControlsBar, BannerAdView
  Resources/   Assets.xcassets (AppIcon, AccentColor, LaunchBackground, Breeds/*)
PupdokuTests/  SudokuEngineTests
scripts/       macincloud-setup.sh, gen_breeds.py, gen_icon.py
docs/          GitHub Pages marketing site
```

Art is generated deterministically: `scripts/gen_breeds.py` (breed SVGs) and
`scripts/gen_icon.py` (app icon). Re-run either to regenerate.

## Build (XcodeGen)

This repo has no committed `.xcodeproj` — it's generated from `project.yml`.

```bash
# one-time on a fresh Mac / MacInCloud box
bash scripts/macincloud-setup.sh

xcodegen generate
open Pupdoku.xcodeproj
```

## Before shipping — TODO

- **AdMob**: ✅ done — App ID `…~6044441811` in `project.yml`; banner /
  interstitial / rewarded unit IDs in `Services/AdManager.swift`. (New units can
  take up to an hour to start serving live ads.)
- **App Store Connect**: create the bundle `com.centricfiber.pupdoku`, the IAP
  product IDs in `IAPManager.swift`, the leaderboards + achievements matching the
  IDs in `GameCenterManager.swift` / `Achievement.swift`, and the iCloud
  container `iCloud.com.centricfiber.pupdoku`.
