import 'dart:async';

/// A controllable source of elapsed time for the build-scenario play-out.
///
/// The scenario advances by awaiting [elapse] between phase transitions.
/// Production uses [SchedulerBindingScenarioClock] (real wall-clock delays);
/// tests inject a fake that completes [elapse] on demand, so the state
/// machine is exercised deterministically without real waiting.
///
/// Deliberately a single-method interface so the seam stays a *type* that
/// callers depend on and tests substitute — not a bare function.
// ignore: one_member_abstracts
abstract interface class ScenarioClock {
  /// Completes after [duration] has elapsed.
  Future<void> elapse(Duration duration);
}

/// The production [ScenarioClock] — real wall-clock delays via
/// [Future.delayed].
///
/// Named for the scheduler binding because the delay is driven by the engine's
/// frame/timer scheduler in a running app. Trivial by design: the interesting
/// timing logic lives in the notifier, not here.
final class SchedulerBindingScenarioClock implements ScenarioClock {
  /// Creates the production scenario clock.
  const SchedulerBindingScenarioClock();

  @override
  Future<void> elapse(Duration duration) => Future<void>.delayed(duration);
}
