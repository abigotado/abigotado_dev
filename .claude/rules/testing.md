---
description: Test and golden-baseline rules
paths:
  - test/**/*.dart
---

# Tests

- `test/` mirrors `lib/src/` by feature. If a test can't fail from a real bug,
  don't write it.
- Notifier logic: unit tests via a `ProviderContainer`, disposed in-body — not
  via `addTearDown` when a semantics handle is involved. Widget behavior:
  `ProviderScope(overrides: ...)`, overriding **every** injectable port for
  determinism (never read the real platform).
- Accessibility assertions use `isSemantics` for flag-subset checks —
  `matchesSemantics`/`containsSemantics` compare more than the subset and
  false-fail (since Flutter 3.44).
- Structure: `group('ClassName') > group('method/behavior') >
  test('condition → result')`. No "should" phrasing.
- Pump with explicit surface sizes for layout stability; drive animations with
  `tester.pump(Duration)` — never wall-clock.
- Mock only at boundaries (e.g. a locale source), never internals.

## Goldens

- Golden tests are tagged `golden` and **skip by default** (`dart_test.yaml`):
  local `flutter test` and the main CI gate stay pixel-free. Run them
  explicitly only on Linux: `flutter test --tags golden --run-skipped`.
- Baselines are authored **only** by the owner-triggered `generate` job in
  `.github/workflows/golden.yml` (runs on `main`, pushes a `chore/goldens-*`
  review branch). Never commit Mac-authored goldens — macOS font anti-aliasing
  differs and poisons the baseline; a local `--update-goldens` run is at most a
  throwaway layout preview, discarded before commit (`test/golden/README.md`).
- A PR that changes a section's rendering fails `verify` on the now-stale
  baselines — that is expected: say so in the PR; the owner regenerates on
  `main` after merge.
- Keep goldens deterministic: fixed surface sizes, controlled clock for
  animations, no network.
