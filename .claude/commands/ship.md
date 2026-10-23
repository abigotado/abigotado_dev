---
description: Gate, commit, and open a PR into main (never merges)
---

Ship the current change as a pull request:

1. Run the full gate — the six steps in `/gate` — stopping on the first
   failure.
2. Work from a branch CI runs on — `feat/**`, `fix/**`, `chore/**`, `docs/**`;
   if the current branch doesn't match, create one from it with a descriptive
   name before pushing.
3. Commit with a public-quality conventional message: subject ≤ 72 chars, body
   explains the why. The repo is a showcase — no filler.
4. Push the branch and open the PR into `main` with `gh pr create`
   (title = commit subject; body = what / why / how it was verified) and
   `--assignee @me`.
5. A PR that changes a section's rendering fails the golden `verify` check on
   the now-stale baselines — expected: say so in the PR body
   (`test/golden/README.md`); the owner regenerates baselines on `main` after
   merge.
6. Stop there. Never merge the PR and never push `main` directly — every
   `main` push deploys production (`cd.yml`).

Report the PR URL and the gate results.
