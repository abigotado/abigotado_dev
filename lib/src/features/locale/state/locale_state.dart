import 'dart:ui';

import 'package:abigotado_dev/src/core/locale/supported_locale.dart';
import 'package:equatable/equatable.dart';

/// Immutable snapshot of the locale feature state.
///
/// - [locale] is the Flutter [Locale] currently in effect (always non-null;
///   defaults to the resolved locale on startup).
/// - [manualChoice] is the [SupportedLocale] the user explicitly selected,
///   or `null` when the locale is resolved automatically.
/// - [persistFailed] is `true` when the last attempt to persist a manual
///   choice to the store failed; the choice is still applied in-memory.
final class LocaleState extends Equatable {
  /// Creates an immutable locale state snapshot.
  const LocaleState({
    required this.locale,
    this.manualChoice,
    this.persistFailed = false,
  });

  /// The Flutter [Locale] currently applied to the app.
  final Locale locale;

  /// The locale the user chose explicitly, or `null` for automatic.
  final SupportedLocale? manualChoice;

  /// Whether the last persist attempt failed.
  ///
  /// The UI can surface a subtle error indicator; the choice is still
  /// applied in-memory so the user experience is not broken.
  final bool persistFailed;

  /// Returns a copy of this state with the provided fields overridden.
  LocaleState copyWith({
    Locale? locale,
    // Use a sentinel to distinguish "pass null explicitly" from "omit".
    Object? manualChoice = _omit,
    bool? persistFailed,
  }) {
    return LocaleState(
      locale: locale ?? this.locale,
      manualChoice: manualChoice == _omit
          ? this.manualChoice
          : manualChoice as SupportedLocale?,
      persistFailed: persistFailed ?? this.persistFailed,
    );
  }

  @override
  List<Object?> get props => [locale, manualChoice, persistFailed];
}

/// Sentinel value used by [LocaleState.copyWith] to detect omitted arguments.
const Object _omit = Object();
