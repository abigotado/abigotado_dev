---
description: Run the strict quality gate (CV guard → gen-l10n → codegen drift → format → analyze → test)
---

Run the project's strict gate, in order, stopping at the first failure:

1. `tool/check_cv_pdfs.sh --self-test && tool/check_cv_pdfs.sh` — fail-closed
   phone guard for the public résumé PDFs in `web/cv/`. Needs `pdftotext`
   (poppler); CI installs it, a local run needs it on PATH.
2. `flutter gen-l10n` — the l10n gen output is git-ignored; a fresh checkout
   or worktree has none.
3. `tool/check_codegen_drift.sh` — runs build_runner and fails if any
   `*.g.dart` changed, naming the stale files: commit the regenerated output.
   It compares content before and after, so it works in a dirty tree; CI's
   porcelain drift guard (`ci.yml`) is the equivalent on a clean checkout.
4. `dart format --output=none --set-exit-if-changed .`
5. `flutter analyze --fatal-infos --fatal-warnings`
6. `flutter test`

Rules:

- A failing step is fixed, then the gate re-runs from step 1 — a fix can
  invalidate earlier steps.
- Golden-tagged tests skip locally by design; Linux CI (`golden.yml`) verifies
  them. Never commit locally generated baselines — a local `--update-goldens`
  preview is throwaway, discarded before commit.

Report the result of each step; the gate passes only when all six are green.
