# ARCHITECTURE — abigotado.dev

Clear, enforceable rules for this codebase. `CLAUDE.md` is the source of the
NEVER/ALWAYS list; this document fixes the *structure* so there's no ambiguity
about where things go. The repo is public — the architecture is part of the
portfolio.

## 1. Layering: feature-first

```
lib/
  main.dart                       # entry: runApp(ProviderScope(child: AbigotadoApp()))
  src/
    app/                          # cross-cutting app shell
      app.dart                    # root MaterialApp
      theme/                      # AppColors (tokens), AppTheme
      view/                       # top-level scaffolds the app composes
    core/                         # pure, feature-agnostic helpers
      ...                         # e.g. locale resolution, formatting. No UI.
    features/
      <feature>/
        state/                    # Notifier(s) + immutable Equatable state + providers
        view/                     # screens / sections (ConsumerWidget)
        widget/                   # private widgets owned by this feature
    l10n/                         # arb sources (ru/en/es); gen output git-ignored
```

Rules:

- A feature **never** imports another feature's `state/` or `widget/`. Shared
  needs move to `core/` (logic) or `app/` (shell-level UI).
- `core/` has **no Flutter UI imports** beyond `dart:ui`/`foundation` types it
  genuinely needs — it's pure logic, unit-testable without a widget.
- `theme/` is the only home for colors/sizing tokens. No raw hex in widgets —
  reference `AppColors`.

## 2. State: Riverpod, no codegen

- **Mutable state** → a `Notifier<TState>` whose `TState` is an immutable class
  extending `Equatable`. One notifier per coherent concern (locale, lite-mode,
  build-scenario).
- **Derived/static values** → `Provider`. **Async** → `AsyncNotifier`.
- Providers are **top-level finals** in the feature's `state/` folder. Never
  declare a provider inside `build`.
- Widgets read state with `ConsumerWidget` / `Consumer`: `ref.watch` in `build`,
  `ref.read` in callbacks. Side effects via `ref.listen`, never in `build`.
- Errors are handled **inside the notifier** (`catch (e, s)` + log) and surfaced
  as state; they never escape raw to the UI.
- **No codegen.** No `riverpod_generator`, no `freezed`, no `build_runner`. The
  repo clones and runs with `pub get` alone.

## 3. Widgets

- Compose by **extracting Widget classes**, never `Widget _buildX()` helpers.
- A widget with visual variants is a **sealed base class** with one `build()`,
  abstract getters for the differing primitives, and private factory subclasses;
  `switch (this)` for the parts that vary. Never an enum-driven `if/else`.
- `const` constructors always where possible; `super.key`.
- Spacing via `Row/Column(spacing:)`; sizing via `MediaQuery.sizeOf/paddingOf`.
- `Container` when you need decoration **and** padding; not `DecoratedBox`+`Padding`.

## 4. Internationalization

- `flutter_localizations` + arb files for `ru`, `en`, `es`. arb is the source of
  truth; generated Dart is git-ignored.
- **Every** user-visible string is a key — including the name
  (Никита Коваленко ↔ Nikita Kovalenko). Zero hardcoded display strings.
- Locale resolution order (in `core/`): stored choice → `navigator.languages` →
  timezone→region heuristic → `en`. Manual choice persists and always wins.

## 5. Animation & effects

- Every animated widget reads the **effects mode** (full / lite) and honors
  `prefers-reduced-motion`. Lite mode ships in the *same* change as the effect,
  not later.
- Controllers/tickers are disposed in `dispose()`. No animation drives layout in
  a way that can overflow on mobile.

## 6. Tests

- `test/` mirrors `lib/src/` by feature.
- Notifiers: unit tests via `ProviderContainer` (assert state transitions).
- Sections: golden tests (deterministic — fixed size, controlled clock).
- Widgets: behavior tests with `ProviderScope(overrides: ...)`.
- The rule: if a test can't fail from a real bug, don't write it.

## 7. The strict gate

Nothing is "done" until all three pass — locally and in CI:

```bash
dart format --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings   # zero tolerance: any lint fails
flutter test
```

There is no "info" severity tier in practice: `--fatal-infos` makes every lint a
build failure. Base ruleset is `very_good_analysis` with strict casts, inference,
and raw-types on.
