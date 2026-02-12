# Dartsapp

Pub Darts Challenge - A multiplayer darts challenge game built with Flutter.

## Features

- **6 Challenge Types**: Hit/Miss, Best Score, Closest, Threshold, Countdown, Elimination
- **4 Focus Areas**: Balanced, Scoring, Doubles, Checkouts
- **SQLite Database**: Tracks players, game history, stats, streaks
- **Player Profiles**: Automatic stat tracking (win rate, hit rate, best streak)
- **Match History**: Browse past games with scores and details
- **Sudden Death**: Tied games trigger sudden death rounds
- **Undo System**: Undo up to 10 rounds
- **Dark Theme**: Polished dark UI optimized for pub environments

## Challenge Categories

| Category | Description |
|----------|-------------|
| PRECISION | Hit specific targets (doubles, triples, bull) |
| SCORING | Score thresholds or beat your opponent's score |
| FINISH | Checkout specific numbers (2-170) |
| BATTLE | Head-to-head closest-to-target challenges |
| SPECIAL | Elimination rounds with lives system |

## Setup

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.0+)

### Installation

```bash
# Clone the repo
git clone <repo-url>
cd Dartsapp

# Generate platform files (Android, iOS, web)
flutter create . --project-name dartsapp --org com.dartsapp

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Running on specific platforms

```bash
# iOS Simulator
flutter run -d ios

# Android Emulator
flutter run -d android

# Chrome (web)
flutter run -d chrome
```

## Project Structure

```
lib/
├── main.dart                    # Entry point
├── models/
│   ├── player.dart              # Player data model
│   ├── challenge.dart           # Challenge types & categories
│   ├── game_session.dart        # Game session tracking
│   └── challenge_result.dart    # Per-round results
├── database/
│   └── database_helper.dart     # SQLite operations
├── services/
│   ├── challenge_service.dart   # Challenge generation engine
│   └── audio_service.dart       # Haptic feedback
├── game/
│   └── game_state.dart          # Game controller (ChangeNotifier)
├── theme/
│   └── app_theme.dart           # Dark theme configuration
└── screens/
    ├── home_screen.dart         # Main menu
    ├── game_setup_screen.dart   # Game configuration
    ├── game_screen.dart         # Active game (all input types)
    ├── winner_screen.dart       # End-game results
    ├── players_screen.dart      # Player management & stats
    └── history_screen.dart      # Match history
```

## Database Schema

- **players** - Player profiles with cumulative stats
- **game_sessions** - Each game played with final scores
- **challenge_results** - Per-round, per-player results for detailed analytics
