import 'package:abigotado_dev/src/features/hero/state/build_phase.dart';
import 'package:equatable/equatable.dart';

/// Immutable snapshot of the live "agents build the page" scenario.
///
/// The scenario is a small forward-only state machine driven by
/// `BuildScenarioNotifier`: it starts at [BuildScenarioState.initial] and ends
/// at [BuildScenarioState.released]. Widgets render purely off this snapshot —
/// they never read timers or effects state themselves.
///
/// - [phase] — which step of the play-out is current.
/// - [review] — the reviewer's verdict (only meaningful once the scenario has
///   reached [BuildPhase.reviewing] or [BuildPhase.released]).
/// - [skipped] — `true` once the user pressed Skip; the play-out aborts and
///   jumps to the released snapshot.
/// - [hasError] — `true` if the play-out caught an error; surfaced as state
///   rather than thrown to the UI.
final class BuildScenarioState extends Equatable {
  /// Creates an immutable scenario snapshot.
  const BuildScenarioState({
    required this.phase,
    required this.review,
    required this.skipped,
    required this.hasError,
  });

  /// The opening snapshot: planning, reviewer nitpicking, not skipped, no
  /// error.
  const BuildScenarioState.initial()
    : phase = BuildPhase.planning,
      review = ReviewStatus.nitpicking,
      skipped = false,
      hasError = false;

  /// The terminal snapshot: released and approved.
  ///
  /// Used both as the natural end of the play-out and as the immediate target
  /// when the user skips. [skipped] stays `false` here — it is set explicitly
  /// by the notifier's `skip()` path so the two routes to "released" remain
  /// distinguishable.
  const BuildScenarioState.released()
    : phase = BuildPhase.released,
      review = ReviewStatus.approved,
      skipped = false,
      hasError = false;

  /// Which step of the play-out is current.
  final BuildPhase phase;

  /// The reviewer's current verdict.
  final ReviewStatus review;

  /// Whether the user skipped the play-out.
  final bool skipped;

  /// Whether the play-out caught an error.
  final bool hasError;

  /// Returns a copy of this state with the provided fields overridden.
  ///
  /// All fields are non-nullable, so a plain null-coalescing copy is correct
  /// here — no sentinel needed.
  BuildScenarioState copyWith({
    BuildPhase? phase,
    ReviewStatus? review,
    bool? skipped,
    bool? hasError,
  }) {
    return BuildScenarioState(
      phase: phase ?? this.phase,
      review: review ?? this.review,
      skipped: skipped ?? this.skipped,
      hasError: hasError ?? this.hasError,
    );
  }

  @override
  List<Object?> get props => [phase, review, skipped, hasError];
}
