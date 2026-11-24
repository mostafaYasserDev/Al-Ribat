# Al-Ribat: AI Agent Guidelines & Architecture Rules (دستور الذكاء الاصطناعي)

This document is the single source of truth for AI agents (and human developers) modifying this repository.
Follow these rules strictly to prevent context drift, hallucinations, and code degradation.

---

## 1. Core Principles

1. **Context Isolation (العزل السياقي)**:
   - Work strictly within the target feature's boundary. Do NOT read or touch unrelated features unless a shared contract in `core/` or `domain/` explicitly requires it.
   - Keep interactions localized to minimize token consumption and avoid hallucinated dependencies.

2. **High Cohesion over Line-Count Limits (التماسك الحقيقي)**:
   - **Never** split a single class into artificial `part` / `part of` mixin files simply to hit an arbitrary line limit (e.g., <= 100 lines).
   - An entity or notifier should be self-contained in its own file with explicit imports, clear encapsulation, and full visibility.

3. **Pure Modern Dart 3 (No Code-Gen Trap)**:
   - Do **NOT** introduce `freezed`, `json_serializable`, or `riverpod_generator` without explicit user instruction.
   - Rely on Dart 3 modern language features: `sealed` classes for states, `records` for lightweight tuples, and pattern matching / switch expressions.

4. **Layer Flow & Dependency Rule**:
   - `presentation -> application -> domain <- data`
   - The `domain` layer has ZERO dependencies on Flutter, Hive, or Firebase.
   - `services` are standalone utilities coordinated at the `application` level.

---

## 2. Directory Structure (Feature-First Evolution)

The project is transitioning to a **Feature-First** structure:
```
lib/
├── app/                  # Application bootstrap, routing, app-level theme
├── core/                 # Shared utilities, failures, constants, security
└── features/             # Vertical feature slices (or domain/data/app slices during transition)
    ├── prayer/           # Adhan calculation, prayer schedules, location
    ├── activities/       # Daily tasks, habits, measurable goals
    ├── projects/         # Project workspaces & task groups
    ├── focus/            # Focus timer, foreground service, pomodoro
    ├── reflections/      # Daily journaling & reflection entries
    └── settings/         # Backups, cloud sync, PIN security, preferences
```

---

## 3. State Management (Riverpod)

- Use explicit Riverpod 2.x `AsyncNotifier` or `Notifier` classes.
- Handle all 3 states in UI using `.when()` or `pattern matching`: data, error, loading.
- Never write raw exception messages to the user; map them to `AppFailure`.

---

## 4. Verification Gate (MUST RUN AFTER ANY CHANGE)

After creating or modifying code, verify with:
```bash
dart format lib test
flutter analyze --no-pub
flutter test --no-pub
```
Zero analyzer errors or warnings allowed. All tests must pass before completing any task.
