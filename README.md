# abigotado.dev

[![CI](https://github.com/abigotado/abigotado_dev/actions/workflows/ci.yml/badge.svg)](https://github.com/abigotado/abigotado_dev/actions/workflows/ci.yml)

<!-- CD badge activates once the Cloudflare Pages deploy is live:
[![CD](https://github.com/abigotado/abigotado_dev/actions/workflows/cd.yml/badge.svg)](https://github.com/abigotado/abigotado_dev/actions/workflows/cd.yml)
-->

Personal site of **Nikita Kovalenko** — Senior Flutter engineer: architecture from scratch, building & leading the team, AI-first processes.

The concept: **the page builds itself in front of you.** A multi-agent pipeline
(`planner → coder → reviewer`) assembles the landing live — the same way this
repo is actually developed. It's not a description of an AI-first process; it's
a demonstration of one.

> Built with Flutter Web. The code is part of the portfolio — so it's held to
> the same bar as the work it describes.

## Highlights

- **Trilingual** — RU / EN / ES with auto-detection (stored choice →
  `navigator.languages` → timezone region → English) and a hot-reload-style
  switch.
- **Wow, but kind** — animations and effects with a mandatory *lite mode*
  (respects `prefers-reduced-motion`, weak GPUs, and a manual toggle).
- **Mobile-first** — designed for the phone, scaled up to the desktop.
- **The code as content** — skills rendered as a `pubspec.yaml`, career as a
  `CHANGELOG.md`, the CTA as a merge button.

## Stack

Flutter Web (CanvasKit) · strict `very_good_analysis` · widget + unit tests · GitHub Actions → Cloudflare Pages.

## Develop

```bash
flutter pub get
flutter run -d chrome      # local dev
flutter analyze            # static analysis (must be clean)
flutter test               # widget + unit tests
dart format .              # formatting
```

## How it's built

This project is developed through a test-driven agent orchestration pipeline —
`planner → advisor → coder → test-writer → coder → reviewer (+ second-opinion)` —
with a human in the loop at every gate. See [`CLAUDE.md`](CLAUDE.md) for the rules
and [`.claude/agents/`](.claude/agents) for the playbooks.
