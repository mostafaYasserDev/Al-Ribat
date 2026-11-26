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

---

## 5. UI/UX Design Language (Telegram + Apple iOS)

Follow this visual and interaction standard for all UI additions and edits (mobile-first, RTL Arabic):

1. **Grouped Surfaces & Tactile Controls**:
   - Prefer inset grouped cards (rounded containers, hairline dividers, subtle borders) and squircle tinted icon badges over flat Material lists.
   - Use uniform, single-row soft-tinted quick-action bars or clean grouped rows instead of cluttered `Wrap` button chips or harsh solid-color Material pills.
   - Soft destructive styling: use muted red text/icon with a light tinted background (`alpha: 0.10–0.14`), never heavy solid red blocks.

2. **Anchored Popovers & Smooth Apple/Telegram Motion**:
   - **Never** use abrupt generic Material `AlertDialog`s for contextual choices or confirmations.
   - Use **anchored floating menus** (`showAnchoredSettingsMenu` pattern: `ScaleTransition` anchored to the tapped widget's `GlobalKey` + `BackdropFilter` blur + fade) so the menu springs out of the pressed button and collapses back into it on dismiss.
   - Wrap expandable sections in `AnimatedSize` / `AnimatedSwitcher` and interactive cards/buttons in `PressableScale` with subtle `HapticFeedback`.

3. **Sliders & Expensive Updates**:
   - Commit slider values on `onChangeEnd` (using local draft state during `onChanged`) to keep UI dragging 60fps without redundant disk writes or provider rebuilds.

---

## 6. Post-Task Delivery

After passing the Verification Gate on any code-modification task:
1. **Push to GitHub**: Stage, commit with a clear message, and push to `origin main`.
2. **Launch / Restart Linux App**: Restart `flutter run -d linux --no-pub` (killing any previous `al_ribat` process cleanly with `pkill -x al_ribat || true`) so the user can preview changes immediately.
