---
description: Run the strict quality gate (CV guard → gen-l10n → codegen → drift check → format → analyze → test)
---

Run the project's strict gate, in order, stopping at the first failure:

1. `tool/check_cv_pdfs.sh --self-test && tool/check_cv_pdfs.sh` — fail-closed
   phone guard for the public résumé PDFs in `web/cv/`. Needs `pdftotext`
   (poppler); CI installs it, a local run needs it on PATH.
2. `flutter gen-l10n` — the l10n gen output is git-ignored; a fresh checkout
   or worktree has none.
3. `dart run build_runner build --delete-conflicting-outputs`
4. `test -z "$(git status --porcelain -- '*.g.dart')"` — drift guard, same as
   CI: the regenerated codegen must already be committed; a failure means
   stage the build_runner output with its source.
5. `dart format --output=none --set-exit-if-changed .`
6. `flutter analyze --fatal-infos --fatal-warnings`
7. `flutter test`

Rules:

- A failing step is fixed, then the gate re-runs from step 1 — a fix can
  invalidate earlier steps.
- Golden-tagged tests skip locally by design; Linux CI (`golden.yml`) verifies
  them. Never commit locally generated baselines — a local `--update-goldens`
  preview is throwaway, discarded before commit.

Report the result of each step; the gate passes only when all seven are green.
