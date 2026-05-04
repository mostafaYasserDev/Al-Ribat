# Al-Ribat (الرباط)

Prayer-centered productivity MVP built with Flutter + Riverpod.

## Features in this MVP

- Dynamic daily prayer times from location (`geolocator` + `adhan`)
- Prayer-phase timeline cards (Fajr, Dhuhr, Asr, Maghrib, Isha)
- Add tasks linked to prayer blocks (`before` / `after`)
- Edit, delete, and reorder tasks inside each prayer phase
- Local persistence with Hive (offline-first)
- Smart suggestion banner based on remaining time and pending tasks
- End-of-day reflection card after Isha + saved reflection history screen
- Persistent streak logic across days
- Weekly/monthly productivity statistics by prayer phase
- Settings screen (theme, method, notifications, focus mode)
- Improved notifications: pre-prayer + after-prayer prompts

## Run

1. Install Flutter SDK and ensure `flutter` is on your PATH.
2. In this project folder, run:

```bash
flutter create .
flutter pub get
flutter run
```

> `flutter create .` will generate missing platform folders (`android/`, `ios/`, etc.) while preserving existing `lib/` and `pubspec.yaml`.

## Suggested next improvements

- Add deep Android focus mode integration with device policy APIs
- Add cloud sync + optional account backup
- Add richer charts and insights
- Expand provider tests and widget golden tests
