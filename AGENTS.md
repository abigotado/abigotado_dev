# AGENTS.md — abigotado.dev

Guidance for Codex and other coding agents. The authoritative rules are in
[`CLAUDE.md`](CLAUDE.md); this is the short version.

## Project

Flutter Web personal landing for Nikita Kovalenko. Public repo — code is a
portfolio artifact. Concept: a multi-agent pipeline "builds" the page live.

## Hard rules (summary — full list in CLAUDE.md)

- Feature-first under `lib/src/`; `package:` imports only; strict
  `very_good_analysis` (analyzer must be clean).
- No `Widget _buildX()` helpers — extract Widget classes. Sealed-class factories
  for widget variants, never enums.
- `const`/`final` by default; `switch` expressions over ternaries; `Row/Column
  (spacing:)` over manual `SizedBox`.
- State: **Riverpod with codegen** (`@riverpod`; committed `*.g.dart`);
  `Equatable` state classes. Errors caught inside the `Notifier` with
  `catch (e, s)` + log; never `catch (_)`.
- All user-visible strings are arb keys in ru/en/es. The name is localized too.
- Every animation has a lite-mode / reduced-motion fallback.
- Never edit generated files.

## Verify before done

```bash
dart run build_runner build --delete-conflicting-outputs   # regen committed codegen
dart format --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings   # any lint fails the build
flutter test                                      # widget + golden, all green
```

## Git

Local-first. No remote or push until the owner explicitly approves. Commit
messages are public — keep them meaningful.

## Second-opinion

Reviews get a Codex second-opinion pass. If Codex is unavailable, re-run the
reviewer in adversarial mode rather than skipping.
