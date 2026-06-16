import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:equatable/equatable.dart';

/// Immutable snapshot of the effects feature state.
///
/// - [manualChoice] is the [EffectsMode] the user explicitly selected, or
///   `null` when the mode is resolved automatically from OS and viewport
///   signals. The notifier holds ONLY the manual choice; the effective mode
///   is resolved at the widget layer via `effectsModeOf`.
/// - [persistFailed] is `true` when the last attempt to persist a manual
///   choice to the store failed; the choice is still applied in-memory.
final class EffectsState extends Equatable {
  /// Creates an immutable effects state snapshot.
  const EffectsState({this.manualChoice, this.persistFailed = false});

  /// The mode the user chose explicitly, or `null` for automatic resolution.
  final EffectsMode? manualChoice;

  /// Whether the last persist attempt failed.
  ///
  /// The UI can surface a subtle error indicator; the choice is still
  /// applied in-memory so the user experience is not broken.
  final bool persistFailed;

  /// Returns a copy of this state with the provided fields overridden.
  ///
  /// Pass `manualChoice: null` explicitly to clear the manual choice; omitting
  /// the parameter preserves the current value. This is the single state-update
  /// path — direct construction is reserved for the notifier's `build` method.
  EffectsState copyWith({
    // Sentinel distinguishes "pass null explicitly" from "omit the parameter".
    Object? manualChoice = _omit,
    bool? persistFailed,
  }) {
    return EffectsState(
      manualChoice: manualChoice == _omit
          ? this.manualChoice
          : manualChoice as EffectsMode?,
      persistFailed: persistFailed ?? this.persistFailed,
    );
  }

  @override
  List<Object?> get props => [manualChoice, persistFailed];
}

/// Sentinel value used by [EffectsState.copyWith] to detect omitted arguments.
const Object _omit = Object();
