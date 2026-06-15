import 'dart:developer' as developer;

import 'package:abigotado_dev/src/core/locale/locale_resolver.dart';
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
@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  /// Monotonically-increasing counter used to guard against stale async
  /// completions clobbering newer state (see [setLocale] / [clearChoice]).
  int _opVersion = 0;

  @override
  LocaleState build() {
    final reader = ref.watch(platformReaderProvider);
    final store = ref.watch(localeStoreProvider);
    final stored = store.read();
    final resolved = resolveLocale(
      stored: stored,
      platformLocales: reader.locales,
      timeZoneId: reader.timeZoneId,
    );
    return LocaleState(locale: resolved.toLocale(), manualChoice: stored);
  }

  /// Applies [locale] immediately (in-memory) and persists it to
  /// [LocaleStore]. If the persist step fails, [LocaleState.persistFailed]
  /// is set to `true` but the locale flip is preserved.
  ///
  /// Note: store-write ordering is safe on the web target (localStorage is
  /// synchronous under the hood). Full cross-platform write-serialization
  /// (queue / mutex) is a deferred robustness item — not needed for a
  /// 3-locale toggle.
  Future<void> setLocale(SupportedLocale locale) async {
    final op = ++_opVersion;
    state = state.copyWith(
      locale: locale.toLocale(),
      manualChoice: locale,
      persistFailed: false,
    );
    try {
      await ref.read(localeStoreProvider).write(locale);
    } on Object catch (e, s) {
      developer.log(
        'locale persist failed',
        error: e,
        stackTrace: s,
        name: 'LocaleNotifier',
      );
      // Guard: skip state update if the notifier was disposed or a newer
      // operation has already superseded this one.
      if (!ref.mounted || op != _opVersion) return;
      state = state.copyWith(persistFailed: true);
    }
  }

  /// Clears the stored manual choice and reverts to automatic locale
  /// resolution. If the store clear fails, [LocaleState.persistFailed]
  /// is set to `true` but the re-resolved locale is still applied.
  ///
  /// Note: store-write ordering is safe on the web target (localStorage is
  /// synchronous under the hood). Full cross-platform write-serialization
  /// (queue / mutex) is a deferred robustness item — not needed for a
  /// 3-locale toggle.
  Future<void> clearChoice() async {
    final op = ++_opVersion;
    final reader = ref.read(platformReaderProvider);
    final resolved = resolveLocale(
      platformLocales: reader.locales,
      timeZoneId: reader.timeZoneId,
    );
    // Apply re-resolved locale and clear manualChoice immediately (in-memory)
    // so the UI reflects the change without waiting for the store round-trip.
    state = state.copyWith(
      locale: resolved.toLocale(),
      manualChoice: null,
      persistFailed: false,
    );
    try {
      await ref.read(localeStoreProvider).clear();
    } on Object catch (e, s) {
      developer.log(
        'locale clear failed',
        error: e,
        stackTrace: s,
        name: 'LocaleNotifier',
      );
      // Guard: skip state update if the notifier was disposed or a newer
      // operation has already superseded this one.
      if (!ref.mounted || op != _opVersion) return;
      state = state.copyWith(persistFailed: true);
    }
  }
}
