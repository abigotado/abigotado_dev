# CLAUDE.md — abigotado.dev

Personal landing of Nikita Kovalenko. **Flutter Web**, public repo. The code is
itself a portfolio artifact: every line must be review-grade.

Concept and product plan live with the owner's notes (iCloud `Documents/CV/landing/`:
`CONCEPT.md`, `PLAN.md`, `mockup_v1.html`). This file governs *how the code is written*.

## What this is

A landing page whose conceit is that a multi-agent pipeline builds it live
(`planner → coder → reviewer`, reviewer nitpicks then approves, DEBUG→RELEASE).
Trilingual (ru/en/es), mobile-first, heavy on tasteful animation — always with a
**lite mode** escape hatch.

## Architecture

- **Feature-first** under `lib/src/`. Each feature owns its `view/`, state, and
  any local widgets. Shared cross-feature code lives in `lib/src/app/` (theme,
  bootstrap) and `lib/src/core/` (utilities, locale resolution).
- State: minimal and explicit. The build scenario is a small state machine
  (planning → coding → reviewing → released) — model it with a BLoC/Cubit, not
  ad-hoc setState scattered across widgets.
- i18n: `flutter_localizations` + arb files (`ru`/`en`/`es`). The name is a
  localized key (Никита Коваленко ↔ Nikita Kovalenko), not a hardcoded string.
- Generated output (`*.g.dart`, l10n gen) is git-ignored — never edit by hand.

## NEVER

- `Widget _buildX()` helper methods — extract a Widget class instead. (Named
  `Builder`-callbacks are allowed only when data params genuinely can't express it.)
- Enums for widget factory variants — use a sealed base class + private factory
  subclasses (single `build()`, abstract getters for primitives, `switch (this)`
  for the widget-varying parts).
- `DecoratedBox` + `Padding` separately — use `Container` when you need both.
- Manual `SizedBox` spacers between children — use `Row/Column(spacing:)`.
- `MediaQuery.of(context).size/padding` — use `MediaQuery.sizeOf/paddingOf`.
- Editing generated files (`*.g.dart`, `*.freezed.dart`, `*.gr.dart`, l10n gen).
- Relative imports — `package:abigotado_dev/...` everywhere (enforced by lint).
- Nested ternaries — `switch` expression or `if-case`.
- `catch (_)` / silent swallow — `catch (e, s)` and log; handle at the Cubit/BLoC
  boundary, never let it reach the UI raw.
- Hardcoded UI strings — every user-visible string is an arb key in all 3 locales.
- An effect with no lite-mode fallback — animation must degrade gracefully.

## ALWAYS

- `const` constructors and `final` fields wherever possible.
- `switch` expressions over ternaries for conditional values; `if-case` for
  pattern-matched control flow.
- `equatable`/`freezed` for state and model classes.
- `dispose()` controllers, tickers, streams, subscriptions in StatefulWidgets.
- Check `mounted` across async gaps before using `BuildContext`.
- Respect `prefers-reduced-motion` and the manual effects toggle in every
  animated widget.
- Test boundaries, not internals. Write a test only if a real bug could break it.

## Testing

- `test/` mirrors `lib/src/` by feature.
- Golden tests for visual sections (the "golden screenshots pass golden tests"
  conceit is real CI here). Widget tests for locale resolution and the build
  scenario state machine.
- Run before declaring done: `flutter analyze && flutter test`. Analyzer must be
  clean (no infos), tests green.

## Agent workflow

Non-trivial work (new section/feature, ≥3 files, architectural choice) goes
through the pipeline — see `.claude/agents/`:

`planner → advisor (challenge the plan) → coder → reviewer → Codex second-opinion → test-writer`

Orchestration runs at the **main session level** (subagents can't dispatch
subagents). The main session executes the chain the orchestrator playbook
produces. Single-file mechanical fixes may skip the pipeline.

## Verification & git

- Verify locally before every commit: `flutter analyze && flutter test && dart format --set-exit-if-changed .`
- **Local-first**: no remote, no push until the owner explicitly says so.
- Commit messages are public and part of the showcase — write them well.
- Before the first push: audit `git ls-files` by hand; the repo must contain
  nothing but intended, showcase-worthy files.
