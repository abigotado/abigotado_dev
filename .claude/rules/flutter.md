---
description: Widget structure, state, error handling, and animation rules for lib/
paths:
  - lib/**/*.dart
---

# Flutter rules — lib/

## Widgets

- Never write `Widget _buildX()` helper methods — extract a Widget class.
  (Named `Builder`-callbacks are allowed only when data params genuinely can't
  express it.)
- A widget with visual variants is a **sealed base class** with private factory
  subclasses: a single `build()`, abstract getters for the primitives,
  `switch (this)` for the widget-varying parts. Never an enum-driven variant.
- `Container` when you need decoration **and** padding — not
  `DecoratedBox` + `Padding` stacked by hand.
- Spacing via `Row/Column(spacing:)` — no manual `SizedBox` spacers between
  children.
- `MediaQuery.sizeOf/paddingOf(context)` — never `MediaQuery.of(context)`
  for `.size`/`.padding`.
- `switch` expressions over ternaries for conditional values; `if-case` for
  pattern-matched control flow; never nested ternaries.

## State (Riverpod with codegen)

- Mutable state → a `@riverpod` `Notifier` with an immutable state class
  extending `Equatable` (freezed is not used). Derived values → `@riverpod`
  functions. `part '<file>.g.dart';` beside the definition.
- `ConsumerWidget` / `Consumer` to read providers: `ref.watch` in `build`,
  `ref.read` in callbacks, side effects via `ref.listen`. Never create a
  provider inside `build`.
- After changing any `@riverpod` provider: regenerate with `build_runner` and
  commit the `*.g.dart` — the gate's drift check and CI both fail on stale
  output.

## Errors & lifecycle

- Exceptions are handled at the state boundary, inside the `Notifier`:
  `catch (e, s)` + log, surfaced as state. Never `catch (_)`, never a raw
  exception reaching the UI.
- `dispose()` controllers, tickers, streams, subscriptions in StatefulWidgets;
  check `mounted` across async gaps before using `BuildContext`.

## Strings & animation

- Every user-visible string is an arb key in ru/en/es — no hardcoded display
  strings, no concatenation that breaks translation
  (see `.claude/rules/i18n.md`).
- Every animated widget reads the effects mode (full / lite) and honors
  `prefers-reduced-motion`; the lite path ships in the **same change** as the
  effect, never later.
