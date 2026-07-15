import 'dart:async';

import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/features/hero/state/build_phase.dart';
import 'package:abigotado_dev/src/features/hero/state/build_scenario_notifier.dart';
import 'package:abigotado_dev/src/features/hero/widget/agent_status_line.dart';
import 'package:abigotado_dev/src/features/hero/widget/reviewer_comment_card.dart';
import 'package:abigotado_dev/src/features/hero/widget/skip_button.dart';
import 'package:abigotado_dev/src/features/hero/widget/terminal_frame.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The centerpiece hero: the terminal in which the agents "build the page".
///
/// This widget — not the notifier — owns the effects decision. In
/// `didChangeDependencies` (where `MediaQuery` is available) it resolves
/// `effectsModeOf` exactly once and drives the scenario:
/// - **full** → `start()` plays the timed planning → coding → reviewing →
///   released sequence, with animated spinner / cursor;
/// - **lite** → `skip()` jumps straight to the released snapshot, no animation.
///
/// Animation controllers are constructed only in full mode (held nullable) and
/// disposed tolerantly, so lite mode allocates no tickers.
class TerminalHero extends ConsumerStatefulWidget {
  /// Creates the terminal hero.
  const TerminalHero({super.key});

  @override
  ConsumerState<TerminalHero> createState() => _TerminalHeroState();
}

class _TerminalHeroState extends ConsumerState<TerminalHero>
    with TickerProviderStateMixin {
  /// Guards the one-shot effects decision in [didChangeDependencies].
  bool _scenarioStarted = false;

  /// Spinner rotation driver — present only in full mode.
  AnimationController? _spinnerController;

  /// Cursor blink driver — present only in full mode.
  AnimationController? _cursorController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scenarioStarted) return;
    _scenarioStarted = true;

    // `effectsModeOf` reads `MediaQuery` (only available here, not in
    // initState), so the mode is resolved synchronously. Animation
    // controllers are created synchronously too — they need `vsync: this`
    // and touch no providers.
    //
    // The mode is resolved ONCE, at mount, by design: the ≤4s play-out
    // self-terminates, and the accessibility-critical OS reduced-motion signal
    // is what we must honour at first paint. Toggling effects mid-play-out
    // deliberately does not restart the sequence — that is not a bug.
    final mode = effectsModeOf(context, ref);

    if (mode == EffectsMode.full) {
      final spinner = _spinnerController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      );
      final cursor = _cursorController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1100),
      );
      // TickerFutures complete only on stop/dispose — fire-and-forget.
      unawaited(spinner.repeat());
      unawaited(cursor.repeat(reverse: true));
    }

    // Kick the scenario off *after* this build/lifecycle settles. Both
    // `start()` and (synchronous) `skip()` mutate the BuildScenario provider;
    // Riverpod forbids mutating a provider inside a widget life-cycle, so the
    // kickoff is deferred to a microtask and re-guarded with `mounted`.
    final notifier = ref.read(buildScenarioProvider.notifier);
    unawaited(
      Future.microtask(() {
        if (!mounted) return;
        switch (mode) {
          case EffectsMode.full:
            unawaited(notifier.start());
          case EffectsMode.lite:
            notifier.skip();
        }
      }),
    );
  }

  @override
  void dispose() {
    // Tolerant: controllers are null in lite mode.
    _spinnerController?.dispose();
    _cursorController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phase = ref.watch(
      buildScenarioProvider.select((state) => state.phase),
    );
    final spinnerController = _spinnerController;
    final cursorController = _cursorController;
    final isFull = spinnerController != null;
    final showSkip = isFull && phase != BuildPhase.released;

    return Padding(
      // Vertical breathing room only. Horizontal gutters belong to
      // TerminalFrame's own ContentWidth — an outer horizontal padding here
      // would shift the frame's column relative to the content cards and
      // break the deliberate right-edge alignment between the terminal and
      // the cards below it.
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: TerminalFrame(
        // Controllers are non-null only in full mode; lite mode passes `null`
        // so the frame/timeline render their static fallbacks.
        cursor: cursorController == null
            ? null
            : _BlinkingCursor(controller: cursorController),
        children: [
          _AgentTimeline(
            phase: phase,
            spinner: spinnerController == null
                ? null
                : _SpinnerGlyph(controller: spinnerController),
          ),
          const ReviewerCommentCard(),
          if (showSkip) const SkipButton(),
        ],
      ),
    );
  }
}

/// The spinner glyph for the running line. Consumes (does not own) the
/// rotation [controller] created and disposed by [_TerminalHeroState]; it is
/// instantiated only in full mode, so lite mode renders a static fallback.
class _SpinnerGlyph extends StatelessWidget {
  const _SpinnerGlyph({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: controller,
      child: const Icon(Icons.sync, size: 12, color: AppColors.accentAmber),
    );
  }
}

/// The blinking command-line caret. Consumes (does not own) the blink
/// [controller] created and disposed by [_TerminalHeroState]; it is
/// instantiated only in full mode, so lite mode renders no caret.
class _BlinkingCursor extends StatelessWidget {
  const _BlinkingCursor({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: controller,
      child: Container(width: 8, height: 16, color: AppColors.accentTeal),
    );
  }
}

/// The three agent status lines, derived from the current [phase].
///
/// Each agent's line shows its task label with a glyph that reflects whether
/// the agent is pending, running, or done at [phase]. The running line is
/// handed the [spinner] (animated in full mode, `null` in lite).
class _AgentTimeline extends StatelessWidget {
  const _AgentTimeline({required this.phase, required this.spinner});

  final BuildPhase phase;
  final Widget? spinner;

  // Agent identifiers are code-identity literals, not arb keys.
  static const String _planner = 'planner';
  static const String _coder = 'coder';
  static const String _reviewer = 'reviewer';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final planner = switch (phase) {
      BuildPhase.planning => AgentStatusLine.running(
        agentName: _planner,
        statusLabel: l10n.t1,
        spinner: spinner,
      ),
      _ => AgentStatusLine.done(agentName: _planner, statusLabel: l10n.t1),
    };

    final coder = switch (phase) {
      BuildPhase.planning => AgentStatusLine.pending(
        agentName: _coder,
        statusLabel: l10n.t2,
      ),
      BuildPhase.coding => AgentStatusLine.running(
        agentName: _coder,
        statusLabel: l10n.t2,
        spinner: spinner,
      ),
      _ => AgentStatusLine.done(agentName: _coder, statusLabel: l10n.t2),
    };

    final reviewer = switch (phase) {
      BuildPhase.planning || BuildPhase.coding => AgentStatusLine.pending(
        agentName: _reviewer,
        statusLabel: l10n.rev_run,
      ),
      BuildPhase.reviewing => AgentStatusLine.running(
        agentName: _reviewer,
        statusLabel: l10n.rev_run,
        spinner: spinner,
      ),
      BuildPhase.released => AgentStatusLine.done(
        agentName: _reviewer,
        statusLabel: l10n.rev_done,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [planner, coder, reviewer],
    );
  }
}
