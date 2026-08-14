# 🎮 Spell & Shape Quest

> An animated, educational spelling and hidden-pattern puzzle game for children aged 7–13. Built with Flutter, zero backend, offline-first.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.3%2B-blue?logo=dart)
![Tests](https://img.shields.io/badge/tests-passing-brightgreen)
![Platforms](https://img.shields.io/badge/platforms-Android%20%7C%20iOS-lightgrey)

---

## 🧩 Concept

Players unscramble letters to spell a mystery word. When correct, the letters connect to reveal a geometric shape hidden inside the word. Five different game modes keep every playthrough fresh.

**Answers are always hidden** on the level-selection screen — the player sees only the mode, category, difficulty and letter count.

---

## 🗂️ Architecture

```
lib/
├── app/
│   ├── app.dart              # Root MaterialApp widget
│   └── routes/
│       ├── app_router.dart   # Named route generation
│       └── route_names.dart  # Route name constants
│
├── core/
│   ├── constants/            # AppColors, AppStrings, AppConstants
│   ├── services/
│   │   ├── local_storage_service.dart  # SharedPreferences wrapper
│   │   ├── tts_service.dart            # Real flutter_tts on-device speech
│   │   └── haptic_service.dart         # Vibration feedback
│   └── utils/
│       └── difficulty_config.dart      # Easy / Medium / Hard parameters
│
├── data/
│   ├── models/               # WordContent, GeneratedChallenge, PlayerProgress …
│   ├── generators/
│   │   ├── challenge_generator.dart    # 100 words x 5 modes = 500 challenges
│   │   └── pattern_generator.dart      # Geometric shapes for 4-8 letter words
│   ├── repositories/
│   │   ├── word_repository.dart        # Word data access + category queries
│   │   └── challenge_repository.dart   # Challenge packs, daily quest, progress save
│   └── sources/
│       └── local_word_data_source.dart # Loads assets/data/word_levels.json
│
├── features/
│   ├── splash/         # Animated splash screen
│   ├── onboarding/     # 3-slide onboarding carousel
│   ├── home/           # Dashboard with live stats
│   ├── level_selection/# 10 Level Packs, spoiler-free challenge cards
│   ├── game/           # 5-mode game screen + GameController
│   ├── daily_challenge/# Deterministic offline Daily Quest
│   └── word_collection/# Discovered word vocabulary gallery
│
├── shared/
│   └── widgets/        # SpaceBackground, reusable components
│
└── main.dart           # Entry point -- bootstraps services, runs app
```

---

## 📚 100-Word Engine

Words are stored in [`assets/data/word_levels.json`](assets/data/word_levels.json) — a hand-curated list of **100 unique, age-appropriate English words** (ages 7–13).

| Property | Detail |
|---|---|
| Total words | 100 |
| Categories | 10 (Animals, Nature, Home, School, Food, Body & Health, Space & Science, Action Words, Places & Transport, Feelings & Values) |
| Words per category | 10 |
| Word length | 4–8 letters |
| Difficulty | Easy 40%, Medium 40%, Hard 20% |
| Languages | English + Marathi + Hindi meanings |
| Extras | Emoji, pronunciation guide, category, pattern template, min. age |

---

## 🎮 500-Challenge Generator

```
100 words x 5 game modes = 500 challenges
```

Generated deterministically at startup by [`ChallengeGenerator`](lib/data/generators/challenge_generator.dart). No hardcoding — add a word and one new challenge per mode appears automatically.

### 5 Game Modes

| # | Mode | Description |
|---|---|---|
| 1 | **Unscramble & Draw** | Rearrange shuffled letters into the correct word; shape is drawn on success |
| 2 | **Missing Letter** | Some letters are blanked out — pick the right ones from choices |
| 3 | **Listen & Spell** | Tap the speaker to hear the word, then spell it without seeing it |
| 4 | **Memory Letters** | Letters are briefly shown, then hidden — recall and spell from memory |
| 5 | **Timed Challenge** | Race against a countdown timer to spell the word correctly |

### Dynamic Pattern Engine

Every correctly-spelled word reveals a geometric shape drawn between the letter nodes:

| Word Length | Shapes |
|---|---|
| 4 letters | Diamond, Square, Kite |
| 5 letters | Star, House, Crown, Heart, Tree |
| 6 letters | Hexagon, Lightning, Rocket |
| 7 letters | Spiral, Mountain, Wave |
| 8 letters | Flower, Octagon, Butterfly |

---

## 📦 10 Level Packs

Challenges are grouped into **10 packs of 50 levels** each on the level-selection screen. Packs are unlocked sequentially — complete Pack 1 to unlock Pack 2.

---

## 📅 Daily Challenge

One challenge is selected deterministically from the 500 using the local date (`daysSinceEpoch % 500`). It resets every midnight. Completion is date-keyed in SharedPreferences — playing again is allowed as practice.

---

## 📖 Word Collection

Words that a player has successfully spelled appear in the My Word Collection gallery with:
- English, Marathi and Hindi meanings
- Emoji
- Pronunciation guide
- Category

Locked words show a blurred card with `?` until discovered.

---

## 🛠️ Setup & Run

### Prerequisites
- Flutter 3.x (`flutter --version`)
- Android SDK or Xcode (for iOS)

### Install

```bash
git clone <repo-url>
cd name_twist_game
flutter pub get
```

### Run (debug)

```bash
flutter run
```

### Run on a specific device

```bash
flutter devices
flutter run -d <device-id>
```

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run a single test file
flutter test test/unit/challenge_generator_test.dart
```

### Test files

| File | What it tests |
|---|---|
| `test/unit/content_validation_test.dart` | 100 words, 10 categories, length & metadata constraints |
| `test/unit/challenge_generator_test.dart` | 500 challenges, 100/mode, 50/pack, deterministic IDs |
| `test/unit/game_controller_test.dart` | Core controller — lives, stars, undo, resetLives, out-of-lives |
| `test/unit/game_controller_modes_test.dart` | All 5 modes — selection, missing letter fill/clear, memory, timed |
| `test/unit/progress_persistence_test.dart` | Save/load stars, unlock levels, word collection, total stars |
| `test/unit/daily_challenge_test.dart` | Determinism, date-keyed completion, index bounds |
| `test/widget/level_card_test.dart` | Spoiler-free cards — locked, incomplete and completed states |
| `test/widget_test.dart` | GameScreen renders all 5 modes; responsive on 360/393/412 px |

---

## 🔍 Code Quality

```bash
# Static analysis (zero issues expected)
flutter analyze

# Auto-format
dart format lib/ test/
```

---

## 📱 Release Build

### Debug APK (for local testing)

```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Release APK (signed, optimised)

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk (~44 MB)
```

### Android App Bundle (for Play Store)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

> **Note**: For Play Store, add a keystore and configure `android/app/build.gradle` signing config before building the AAB.

---

## 🚫 Out of Scope (by design)

- No backend, no database
- No user login or accounts
- No in-app purchases
- No ads
- No analytics tracking

The game is fully offline and privacy-respecting.

---

## 📄 License

This project is private and not published to pub.dev (`publish_to: "none"`).
