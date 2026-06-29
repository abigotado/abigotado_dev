# Golden tests

Pixel baselines for the static sections — the "golden screenshots pass golden
tests" conceit, made real. They catch visual regressions (color tokens,
spacing, font metrics, layout) that the structural widget tests can't see.

## The one rule: baselines are **Linux-only**

Golden PNGs are authored and verified **only on the CI Linux runner**. macOS and
Windows render font anti-aliasing differently, so a baseline made anywhere but
Linux will fail the CI `verify` job. **Never commit a baseline generated on a
Mac.**

The pinned SDK (Flutter `3.44.0`) is what makes this deterministic: its bundled
Roboto (`test/flutter_test_config.dart` loads it) is byte-identical on every
machine, so the only cross-OS variance left is the rasterizer — which the
Linux-only rule absorbs. Bumping Flutter requires regenerating every baseline in
the same change.

## How goldens are wired

- Golden suites are tagged `@Tags(['golden'])` and **skipped by default** via
  `dart_test.yaml`, so the everyday `flutter test` (local + the main CI gate)
  stays green and never touches pixels.
- `.github/workflows/golden.yml`:
  - **`generate`** — `workflow_dispatch`, owner-triggered: regenerates the Linux
    baselines and pushes them to a `chore/goldens-<run>` branch. Open a PR from
    it to review the rendered screenshots before merging.
  - **`verify`** — on push/PR: runs the goldens against committed baselines.
    Self-skips (green) until baselines exist, so there's no chicken-and-egg.

## Generating / updating baselines

1. Push the section change (or the new golden test) to a branch and merge as
   usual — `verify` skips until baselines exist.
2. On GitHub → **Actions → Golden → Run workflow** (on `main`). It pushes the
   baselines to a `chore/goldens-<run>` branch.
3. Open a PR from that branch, eyeball the screenshots in the diff, and merge.
   The PR's own `verify` run proves they pass on a clean Linux checkout.

After an intentional redesign, repeat steps 2–3 to refresh the baselines.

## Previewing locally (macOS)

Safe to preview the *layout* locally, but the PNGs **will** differ from the Linux
baselines on anti-aliasing — that is expected, not a regression. Do **not**
commit what this produces:

```bash
flutter test --tags golden --run-skipped --update-goldens   # writes throwaway PNGs
git restore . && git clean -fd test/**/goldens               # discard them
```

## Notes

- **Scope:** the three static sections (`metrics`, `pubspec`, `changelog`).
  Animated sections (terminal-hero scenario, living background, hover,
  scroll-reveal) are deferred — they need fake-clock/ticker control for a stable
  frame and will be a later increment.
- **Font:** the SDK ships only Roboto (no monospace), so the pubspec/changelog
  code bodies render in Roboto rather than true monospace. Deterministic and
  legible; vendoring a mono TTF (a tracked binary) is the only way to make the
  goldens *look* monospace, and is intentionally deferred.
