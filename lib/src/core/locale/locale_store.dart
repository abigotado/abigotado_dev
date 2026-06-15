import 'package:abigotado_dev/src/core/locale/supported_locale.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstract persistence port for the user's locale choice.
///
/// Implementations are injected via Riverpod overrides so the core logic
/// stays free of platform storage details.
abstract interface class LocaleStore {
  /// Returns the persisted locale choice, or `null` if none has been stored.
  SupportedLocale? read();

  /// Persists [locale] as the user's explicit choice.
  Future<void> write(SupportedLocale locale);

  /// Removes any persisted choice, reverting to automatic resolution.
  Future<void> clear();
}

/// [SharedPreferences]-backed implementation of [LocaleStore].
///
/// Method bodies are stubs — implemented in the GREEN phase.
final class SharedPreferencesLocaleStore implements LocaleStore {
  /// Creates the store backed by the provided [SharedPreferences] instance.
  const SharedPreferencesLocaleStore(this._prefs);

  // Stored for use in the GREEN phase when the stub methods are implemented.
  // ignore: unused_field
  final SharedPreferences _prefs;

  @override
  SupportedLocale? read() => throw UnimplementedError();

  @override
  Future<void> write(SupportedLocale locale) => throw UnimplementedError();

  @override
  Future<void> clear() => throw UnimplementedError();
}
