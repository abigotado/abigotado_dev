---
description: Run the strict quality gate (codegen → format → analyze → test)
---

Run the project's strict gate, in order, stopping at the first failure:

1. `flutter gen-l10n` — the l10n gen output is git-ignored; a fresh checkout
   or worktree has none.
2. `dart run build_runner build --delete-conflicting-outputs`
3. `dart format --set-exit-if-changed .`
4. `flutter analyze --fatal-infos --fatal-warnings`
5. `flutter test`

Rules:

- A failing step is fixed, then the gate re-runs from step 1 — a fix can
  invalidate earlier steps.
- Golden-tagged tests skip locally by design; Linux CI (`golden.yml`) verifies
  them. Never run `--update-goldens` locally.
- If build_runner changed any `*.g.dart`, that regenerated output belongs in
  the same commit as its source.

Report the result of each step; the gate passes only when all five are green.
