import 'package:abigotado_dev/src/features/readme/state/presentation_view.dart';
import 'package:equatable/equatable.dart';

/// Immutable snapshot of which [PresentationView] is currently shown.
///
/// Deliberately the simplest possible state in the app: a single field with
/// no history, no error channel, no async. See `PresentationNotifier` for why
/// this is intentionally simpler than `EffectsNotifier` or
/// `BuildScenarioState`.
final class PresentationState extends Equatable {
  /// Creates an immutable presentation snapshot.
  ///
  /// Defaults to [PresentationView.pitch] — the landing page always opens on
  /// the pitch, never the README.
  const PresentationState({this.view = PresentationView.pitch});

  /// Which presentation is currently shown.
  final PresentationView view;

  /// Returns a copy of this state with [view] overridden.
  ///
  /// The single field is non-nullable, so a plain null-coalescing copy is
  /// correct here — no sentinel needed.
  PresentationState copyWith({PresentationView? view}) {
    return PresentationState(view: view ?? this.view);
  }

  @override
  List<Object?> get props => [view];
}
