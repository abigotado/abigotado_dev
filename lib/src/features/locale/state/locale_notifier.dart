import 'package:abigotado_dev/src/core/locale/locale_store.dart';
import 'package:abigotado_dev/src/core/locale/platform_locale_reader.dart';
import 'package:abigotado_dev/src/core/locale/supported_locale.dart';
import 'package:abigotado_dev/src/features/locale/state/locale_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_notifier.g.dart';

/// Provides the [LocaleStore] implementation.
///
/// Must be overridden at the [ProviderScope] root before the app starts —
/// see `main.dart`. Test suites override it with a fake or in-memory store.
@riverpod
LocaleStore localeStore(Ref ref) =>
    throw UnimplementedError('override at bootstrap/in tests');

/// Provides the [PlatformLocaleReader] implementation.
///
/// Defaults to [WidgetsBindingPlatformLocaleReader], which is safe for
/// production. Tests may override with a controlled fake.
@riverpod
PlatformLocaleReader platformReader(Ref ref) =>
    const WidgetsBindingPlatformLocaleReader();

/// Manages the locale state machine for abigotado.dev.
///
/// Reads the initial locale from the [LocaleStore] and
/// [PlatformLocaleReader], applies user choices immediately (in-memory),
/// and persists them asynchronously. Persist failures are surfaced via
/// [LocaleState.persistFailed] rather than thrown to the UI.
///
/// Stub — logic implemented in the GREEN phase.
@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  @override
  LocaleState build() => throw UnimplementedError();

  /// Applies [locale] immediately and persists it to [LocaleStore].
  ///
  /// Stub — implemented in the GREEN phase.
  Future<void> setLocale(SupportedLocale locale) async =>
      throw UnimplementedError();

  /// Clears the stored manual choice and reverts to automatic resolution.
  ///
  /// Stub — implemented in the GREEN phase.
  Future<void> clearChoice() async => throw UnimplementedError();
}
