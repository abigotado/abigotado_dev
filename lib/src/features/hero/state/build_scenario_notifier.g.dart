// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_scenario_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the [ScenarioClock] that drives the build-scenario play-out.
///
/// Defaults to the real [SchedulerBindingScenarioClock]; tests override it with
/// a controllable fake so phase transitions are deterministic.

@ProviderFor(scenarioClock)
final scenarioClockProvider = ScenarioClockProvider._();

/// Provides the [ScenarioClock] that drives the build-scenario play-out.
///
/// Defaults to the real [SchedulerBindingScenarioClock]; tests override it with
/// a controllable fake so phase transitions are deterministic.

final class ScenarioClockProvider
    extends $FunctionalProvider<ScenarioClock, ScenarioClock, ScenarioClock>
    with $Provider<ScenarioClock> {
  /// Provides the [ScenarioClock] that drives the build-scenario play-out.
  ///
  /// Defaults to the real [SchedulerBindingScenarioClock]; tests override it with
  /// a controllable fake so phase transitions are deterministic.
  ScenarioClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scenarioClockProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scenarioClockHash();

  @$internal
  @override
  $ProviderElement<ScenarioClock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ScenarioClock create(Ref ref) {
    return scenarioClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScenarioClock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScenarioClock>(value),
    );
  }
}

String _$scenarioClockHash() => r'ece6ff6ed3623a1a2a3fbd5c0a89ee735cd2ba86';

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

@ProviderFor(BuildScenarioNotifier)
final buildScenarioProvider = BuildScenarioNotifierProvider._();

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
final class BuildScenarioNotifierProvider
    extends $NotifierProvider<BuildScenarioNotifier, BuildScenarioState> {
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
  BuildScenarioNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'buildScenarioProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$buildScenarioNotifierHash();

  @$internal
  @override
  BuildScenarioNotifier create() => BuildScenarioNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BuildScenarioState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BuildScenarioState>(value),
    );
  }
}

String _$buildScenarioNotifierHash() =>
    r'ff5add236af8c072f1b487359614606afe4d15eb';

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

abstract class _$BuildScenarioNotifier extends $Notifier<BuildScenarioState> {
  BuildScenarioState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<BuildScenarioState, BuildScenarioState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BuildScenarioState, BuildScenarioState>,
              BuildScenarioState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
