import 'dart:async';

import 'package:abigotado_dev/src/core/clock/scenario_clock.dart';
import 'package:abigotado_dev/src/features/hero/state/build_phase.dart';
import 'package:abigotado_dev/src/features/hero/state/build_scenario_notifier.dart';
import 'package:abigotado_dev/src/features/hero/state/build_scenario_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake clocks — no real wall-clock in tests.
// ---------------------------------------------------------------------------

/// A [ScenarioClock] whose [elapse] calls are queued and completed on demand.
///
/// Call [advance] to resolve the next pending [elapse] future (and drain
/// microtasks) so the notifier can progress one phase at a time without
/// real wall-clock delays.
final class _FakeScenarioClock implements ScenarioClock {
  final List<Completer<void>> _queue = [];

  /// Completes the next pending [elapse] call and drains microtasks.
  ///
  /// Throws [StateError] if no [elapse] is pending.
  Future<void> advance() async {
    if (_queue.isEmpty) {
      throw StateError(
        'No pending elapse to advance — is start() running?',
      );
    }
    _queue.removeAt(0).complete();
    // Drain microtasks so the notifier resumes after `await clock.elapse`.
    await Future<void>.value();
  }

  @override
  Future<void> elapse(Duration duration) {
    final completer = Completer<void>();
    _queue.add(completer);
    return completer.future;
  }
}

/// A [ScenarioClock] whose [elapse] always throws.
///
/// Used to verify the error-surface path in [BuildScenarioNotifier.start].
final class _ThrowingScenarioClock implements ScenarioClock {
  const _ThrowingScenarioClock();

  @override
  Future<void> elapse(Duration duration) async =>
      throw Exception('clock failure');
}

// ---------------------------------------------------------------------------
// Helper: build a ProviderContainer with the fake clock injected.
// ---------------------------------------------------------------------------

ProviderContainer _makeContainer(ScenarioClock clock) {
  final container = ProviderContainer(
    overrides: [scenarioClockProvider.overrideWithValue(clock)],
  );
  addTearDown(container.dispose);
  return container;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('BuildScenarioNotifier', () {
    // -----------------------------------------------------------------------
    group('build', () {
      test(
        'build → initial() '
        '(planning, nitpicking, skipped=false, hasError=false)',
        () {
          final container = _makeContainer(_FakeScenarioClock());

          final state = container.read(buildScenarioProvider);

          expect(state, equals(const BuildScenarioState.initial()));
          expect(state.phase, equals(BuildPhase.planning));
          expect(state.review, equals(ReviewStatus.nitpicking));
          expect(state.skipped, isFalse);
          expect(state.hasError, isFalse);
        },
      );
    });

    // -----------------------------------------------------------------------
    group('start', () {
      test(
        'start() then advance steps → '
        'planning→coding→reviewing→released; '
        'review transitions nitpicking→approved at released',
        () async {
          final clock = _FakeScenarioClock();
          final container = _makeContainer(clock);
          final notifier = container.read(buildScenarioProvider.notifier);

          // Begin the play-out (blocks until all 3 elapses are advanced).
          unawaited(notifier.start());

          // Drain the start() call so the first elapse is pending.
          await Future<void>.value();

          // Before first advance: still planning.
          expect(
            container.read(buildScenarioProvider).phase,
            equals(BuildPhase.planning),
          );

          // Advance past planning → coding.
          await clock.advance();
          expect(
            container.read(buildScenarioProvider).phase,
            equals(BuildPhase.coding),
          );
          expect(
            container.read(buildScenarioProvider).review,
            equals(ReviewStatus.nitpicking),
          );

          // Advance past coding → reviewing.
          await clock.advance();
          expect(
            container.read(buildScenarioProvider).phase,
            equals(BuildPhase.reviewing),
          );
          expect(
            container.read(buildScenarioProvider).review,
            equals(ReviewStatus.nitpicking),
          );

          // Advance past reviewing → released, review approved.
          await clock.advance();
          expect(
            container.read(buildScenarioProvider).phase,
            equals(BuildPhase.released),
          );
          expect(
            container.read(buildScenarioProvider).review,
            equals(ReviewStatus.approved),
          );
          expect(container.read(buildScenarioProvider).skipped, isFalse);
          expect(container.read(buildScenarioProvider).hasError, isFalse);
        },
      );

      test(
        'start() with throwing clock → hasError=true, '
        'no exception escapes, state not released',
        () async {
          const clock = _ThrowingScenarioClock();
          final container = _makeContainer(clock);
          final notifier = container.read(buildScenarioProvider.notifier);

          await expectLater(notifier.start(), completes);

          final state = container.read(buildScenarioProvider);
          expect(state.hasError, isTrue);
          // Error path must not spuriously flip to released.
          expect(state.phase, isNot(equals(BuildPhase.released)));
        },
      );
    });

    // -----------------------------------------------------------------------
    group('skip', () {
      test(
        'skip() from initial → '
        'phase=released, review=approved, skipped=true, hasError=false',
        () {
          final container = _makeContainer(_FakeScenarioClock());
          container.read(buildScenarioProvider.notifier).skip();

          final state = container.read(buildScenarioProvider);
          expect(state.phase, equals(BuildPhase.released));
          expect(state.review, equals(ReviewStatus.approved));
          expect(state.skipped, isTrue);
          expect(state.hasError, isFalse);
        },
      );

      test(
        'skip() after released → idempotent '
        '(phase stays released, review approved)',
        () {
          final container = _makeContainer(_FakeScenarioClock());
          final notifier = container
            ..read(buildScenarioProvider.notifier).skip()
            ..read(buildScenarioProvider.notifier).skip();

          final state = notifier.read(buildScenarioProvider);
          expect(state.phase, equals(BuildPhase.released));
          expect(state.review, equals(ReviewStatus.approved));
          expect(state.skipped, isTrue);
        },
      );

      test(
        'skip() mid-start() at planning → released immediately; '
        'advance of stale elapse does not regress phase (stale-guard)',
        () async {
          final clock = _FakeScenarioClock();
          final container = _makeContainer(clock);
          final notifier = container.read(buildScenarioProvider.notifier);

          // Start the play-out (blocks on the first elapse).
          unawaited(notifier.start());
          await Future<void>.value();

          expect(
            container.read(buildScenarioProvider).phase,
            equals(BuildPhase.planning),
          );

          // Skip while planning is in progress.
          notifier.skip();

          expect(
            container.read(buildScenarioProvider).phase,
            equals(BuildPhase.released),
          );
          expect(container.read(buildScenarioProvider).skipped, isTrue);

          // Advance the still-pending elapse — stale-guard must absorb it.
          await clock.advance();

          // Phase must remain released, not regress to coding.
          expect(
            container.read(buildScenarioProvider).phase,
            equals(BuildPhase.released),
          );
          expect(
            container.read(buildScenarioProvider).review,
            equals(ReviewStatus.approved),
          );
        },
      );

      test(
        'skip() mid-start() at coding → stays released after remaining '
        'elapse is advanced (stale-guard at every check-point)',
        () async {
          final clock = _FakeScenarioClock();
          final container = _makeContainer(clock);
          final notifier = container.read(buildScenarioProvider.notifier);

          unawaited(notifier.start());
          await Future<void>.value();

          // Advance to coding.
          await clock.advance();
          expect(
            container.read(buildScenarioProvider).phase,
            equals(BuildPhase.coding),
          );

          // Skip while coding.
          notifier.skip();
          expect(
            container.read(buildScenarioProvider).phase,
            equals(BuildPhase.released),
          );
          expect(container.read(buildScenarioProvider).skipped, isTrue);

          // Advance the pending review elapse — must be a no-op.
          await clock.advance();

          expect(
            container.read(buildScenarioProvider).phase,
            equals(BuildPhase.released),
          );
          expect(
            container.read(buildScenarioProvider).review,
            equals(ReviewStatus.approved),
          );
        },
      );
    });
  });
}
