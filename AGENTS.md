# AGENTS.md — abigotado.dev

Entry point for coding agents. The rulebook is [`CLAUDE.md`](CLAUDE.md)
(index + review blockers), the path-scoped rules under
[`.claude/rules/`](.claude/rules/) — [`flutter.md`](.claude/rules/flutter.md),
[`i18n.md`](.claude/rules/i18n.md), [`testing.md`](.claude/rules/testing.md) —
and [`ARCHITECTURE.md`](ARCHITECTURE.md) for structure. Read them before
writing code; this file intentionally repeats nothing from them.

Flutter Web personal landing; public repo — code, commits, and PRs are all
portfolio surface.

## Verify before done

```bash
flutter gen-l10n                                           # git-ignored gen; a fresh checkout has none
dart run build_runner build --delete-conflicting-outputs   # regen committed codegen
dart format --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings   # any lint fails the build
flutter test   # golden-tagged tests skip locally (Linux CI verifies them)
```

## Git

Work lands via pull requests into `main`; never push or merge `main` directly —
a `main` push deploys production (`cd.yml`). Branch prefixes CI runs on:
`feat/**`, `fix/**`, `chore/**`, `docs/**`. Golden baselines regenerate only
via the owner-triggered `generate` job in `golden.yml`.
