# CLAUDE.md — abigotado.dev

Personal landing of Nikita Kovalenko. **Flutter Web**, public repo. The code is
itself a portfolio artifact: every line must be review-grade.

This file is the always-loaded index: what the project is, the review blockers,
the gate, the workflow. The detailed rulebook is path-scoped under
[`.claude/rules/`](.claude/rules/) and loads with the files it governs;
structure lives in [`ARCHITECTURE.md`](ARCHITECTURE.md). Concept and product
plan live in the owner's notes, outside the repo.

## Scope & layering

The committed harness is self-contained: everything needed to contribute
correctly is in this repo or enforced mechanically (analyzer, CI, the
permission denials in `.claude/settings.json`). On the owner's machine a
user-scope harness layers generic engineering rules on top; nothing here
depends on it, and nothing from it is duplicated here.

## What this is

A landing page whose conceit is that a multi-agent pipeline builds it live
(`planner → coder → reviewer`, reviewer nitpicks then approves, DEBUG→RELEASE).
Trilingual (ru/en/es), mobile-first, heavy on tasteful animation — always with a
**lite mode** escape hatch.

## Architecture (full detail: ARCHITECTURE.md)

- **Feature-first** under `lib/src/`: `app/` (shell, theme), `core/` (pure
  logic, no UI), `features/<name>/{state,view,widget}`, `l10n/` (arb ru/en/es).
- State: **Riverpod with codegen** — a `@riverpod` `Notifier` exposing an
  immutable `Equatable` state per concern (the build scenario is a state
  machine: planning → coding → reviewing → released); derived values are
  `@riverpod` functions. Freezed is not used.
- Generated `*.g.dart` is **committed** (the repo clones and runs with
  `pub get` alone); l10n gen output is git-ignored. Generated files are never
  edited by hand — regenerate via `build_runner`; `.claude/settings.json`
  denies editing them outright.
- i18n: every user-visible string is an arb key in all three locales — the
  name included (Никита Коваленко ↔ Nikita Kovalenko).

## Rules

| Scope | File | Covers |
|---|---|---|
| `lib/**/*.dart` | [`.claude/rules/flutter.md`](.claude/rules/flutter.md) | widgets, state, errors, animation |
| `lib/src/l10n/**` | [`.claude/rules/i18n.md`](.claude/rules/i18n.md) | arb discipline |
| `test/**/*.dart` | [`.claude/rules/testing.md`](.claude/rules/testing.md) | tests, goldens |

Review blockers — the short form; full statements in the rule files:

- `Widget _buildX()` helpers (extract a Widget class) and enum-driven widget
  variants (sealed base + private factory subclasses).
- Hardcoded UI strings — every string is an arb key in ru/en/es.
- An effect without a lite-mode / `prefers-reduced-motion` fallback.
- `--update-goldens` outside Linux CI — baselines come from `golden.yml` only.
- Hand-edits to generated files.

The analyzer (`very_good_analysis` + strict modes, `--fatal-infos`) carries the
style floor — `const`/`final`, single quotes, `package:` imports — so neither
this file nor the rules restate what already fails the build.

## The gate

Run before declaring anything done — `/gate` runs it; CI (`ci.yml`) repeats it
on every PR:

```bash
flutter gen-l10n                                           # git-ignored gen; a fresh checkout has none
dart run build_runner build --delete-conflicting-outputs   # regen committed codegen
dart format --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings   # ANY lint fails the build
flutter test   # golden-tagged tests skip locally by design (Linux CI verifies)
```

## Agent workflow

Non-trivial work (new section/feature, ≥3 files, architectural choice) goes
through the pipeline — see `.claude/agents/`. It is **test-driven**: tests are
written against the planned contracts and must fail (🔴) before the
implementation makes them pass (🟢).

`planner → advisor (challenge the plan) → coder (contracts/skeleton that
compiles) → test-writer (🔴 failing tests vs the contracts) → coder (🟢
implement to green) → reviewer → Codex second-opinion → refactor`

Dart can't compile a test against a type that doesn't exist, so the coder's
first pass is the public API surface only (signatures + `UnimplementedError`
bodies); the logic lands in the green pass, driven by the red tests. Work with
no unit-testable logic (CI/CD YAML, pure config) skips the red→green loop:
`planner → advisor → coder → reviewer → Codex`.

Orchestration runs at the **main session level** (subagents can't dispatch
subagents). The main session executes the chain the orchestrator playbook
produces. Single-file mechanical fixes may skip the pipeline.

## Git & publication

- Work lands via pull requests into `main` — `/ship` encodes the procedure.
  Never push or merge `main` directly: every `main` push deploys production
  (`cd.yml` → GitHub Pages).
- Branches CI runs on: `feat/**`, `fix/**`, `chore/**`, `docs/**`.
- Golden baselines regenerate only via the owner-triggered `generate` job in
  `golden.yml` (runs on `main`, pushes a `chore/goldens-*` review branch).
- Commit messages and PRs are public and part of the showcase — write them well.
