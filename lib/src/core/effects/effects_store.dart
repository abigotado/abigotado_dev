import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstract persistence port for the user's manual effects-mode choice.
///
/// Implementations are injected via Riverpod overrides so the core logic
/// stays free of platform storage details.
abstract interface class EffectsStore {
  /// Returns the persisted effects-mode choice, or `null` if none has been
  /// stored.
  EffectsMode? read();

  /// Persists [mode] as the user's explicit choice.
  Future<void> write(EffectsMode mode);

  /// Removes any persisted choice, reverting to automatic resolution.
  Future<void> clear();
}

/// [SharedPreferences]-backed implementation of [EffectsStore].
final class SharedPreferencesEffectsStore implements EffectsStore {
  /// Creates the store backed by the provided [SharedPreferences] instance.
  const SharedPreferencesEffectsStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _key = 'effects.mode';

  @override
  EffectsMode? read() => EffectsMode.values.asNameMap()[_prefs.getString(_key)];

  @override
  Future<void> write(EffectsMode mode) => _prefs.setString(_key, mode.name);

  @override
  Future<void> clear() => _prefs.remove(_key);
}
