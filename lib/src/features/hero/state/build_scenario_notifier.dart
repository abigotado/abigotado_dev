import 'dart:developer' as developer;

import 'package:abigotado_dev/src/core/clock/scenario_clock.dart';
import 'package:abigotado_dev/src/features/hero/state/build_phase.dart';
import 'package:abigotado_dev/src/features/hero/state/build_scenario_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'build_scenario_notifier.g.dart';

/// Provides the [ScenarioClock] that drives the build-scenario play-out.
///
/// Defaults to the real [SchedulerBindingScenarioClock]; tests override it with
/// a controllable fake so phase transitions are deterministic.
@riverpod
ScenarioClock scenarioClock(Ref ref) => const SchedulerBindingScenarioClock();

/// Drives the live "agents build the page" scenario as a forward-only state
/// machine: planning → coding → reviewing → released.
///
/// The notifier owns the timing logic only. It does NOT read effects mode or
/// `MediaQuery` — the *view* (`TerminalHero`) decides full-vs-lite via
/// `effectsModeOf` and calls [start] (full) or [skip] (lite). This keeps the
/// notifier a pure, widget-free state machine that is unit-testable with a
/// `ProviderContainer` and a fake [ScenarioClock].
///
/// Errors during play-out are caught and surfaced via
/// [BuildScenarioState.hasError] rather than thrown to the UI.
@riverpod
class BuildScenarioNotifier extends _$BuildScenarioNotifier {
  /// Monotonically-increasing token used to guard against a stale [start]
  /// play-out clobbering newer state after a [skip] or disposal.
  ///
  /// Each [start]/[skip] captures the current value; after every awaited
  /// `clock.elapse` the play-out re-checks `op == _opVersion` (and
  /// `ref.mounted`) and aborts if it lost the race. [skip] bumps this so any
  /// in-flight [start] aborts at its next guard rather than regressing the
  /// already-released snapshot.
  int _opVersion = 0;

  /// How long the planner beat runs before handing off to the coder.
  static const Duration _planDuration = Duration(milliseconds: 500);

  /// How long the coder beat runs before handing off to the reviewer.
  static const Duration _codeDuration = Duration(milliseconds: 600);

  /// The reviewer nitpick beat — the long pause before approval flips the
  /// build to released (DEBUG → RELEASE).
  static const Duration _reviewDuration = Duration(milliseconds: 2500);

  @override
  BuildScenarioState build() => const BuildScenarioState.initial();

  /// Runs the clock-driven play-out from the initial snapshot to released:
  /// planning → coding → reviewing → released (review nitpicking → approved).
  ///
  /// Captures the current [_opVersion] up front and re-checks it (plus
  /// `ref.mounted`) after *every* awaited `clock.elapse`. A concurrent [skip]
  /// or notifier disposal bumps the version / unmounts the ref, so a stale
  /// play-out aborts at its next check-point instead of clobbering the
  /// released snapshot or stepping a disposed notifier.
  ///
  /// Any error from the clock is caught and surfaced via
  /// [BuildScenarioState.hasError] — never thrown to the UI.
  Future<void> start() async {
    final op = ++_opVersion;
    final clock = ref.read(scenarioClockProvider);
    try {
      await clock.elapse(_planDuration);
      if (!ref.mounted || op != _opVersion) return;
      state = state.copyWith(phase: BuildPhase.coding);

      await clock.elapse(_codeDuration);
      if (!ref.mounted || op != _opVersion) return;
      state = state.copyWith(phase: BuildPhase.reviewing);

      await clock.elapse(_reviewDuration);
      if (!ref.mounted || op != _opVersion) return;
      state = const BuildScenarioState.released();
    } on Object catch (e, s) {
      developer.log(
        'build scenario play-out failed',
        error: e,
        stackTrace: s,
        name: 'BuildScenarioNotifier',
      );
      if (!ref.mounted || op != _opVersion) return;
      state = state.copyWith(hasError: true);
    }
  }

  /// Aborts any in-flight play-out and jumps straight to the released
  /// snapshot, flagged as user-skipped.
  ///
  /// Bumps [_opVersion] so the running [start] aborts at its next guard
  /// (rather than regressing this released state), then sets the terminal
  /// snapshot with `skipped: true`. Idempotent: calling it again while already
  /// released yields the same terminal state.
  void skip() {
    _opVersion++;
    state = const BuildScenarioState.released().copyWith(skipped: true);
  }
}
