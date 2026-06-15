// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the [LocaleStore] implementation.
///
/// Must be overridden at the [ProviderScope] root before the app starts —
/// see `main.dart`. Test suites override it with a fake or in-memory store.

@ProviderFor(localeStore)
final localeStoreProvider = LocaleStoreProvider._();

/// Provides the [LocaleStore] implementation.
///
/// Must be overridden at the [ProviderScope] root before the app starts —
/// see `main.dart`. Test suites override it with a fake or in-memory store.

final class LocaleStoreProvider
    extends $FunctionalProvider<LocaleStore, LocaleStore, LocaleStore>
    with $Provider<LocaleStore> {
  /// Provides the [LocaleStore] implementation.
  ///
  /// Must be overridden at the [ProviderScope] root before the app starts —
  /// see `main.dart`. Test suites override it with a fake or in-memory store.
  LocaleStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localeStoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localeStoreHash();

  @$internal
  @override
  $ProviderElement<LocaleStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LocaleStore create(Ref ref) {
    return localeStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocaleStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocaleStore>(value),
    );
  }
}

String _$localeStoreHash() => r'fbca2938459018ea962bcb431ec226489c549a32';

/// Provides the [PlatformLocaleReader] implementation.
///
/// Defaults to [WidgetsBindingPlatformLocaleReader], which is safe for
/// production. Tests may override with a controlled fake.

@ProviderFor(platformReader)
final platformReaderProvider = PlatformReaderProvider._();

/// Provides the [PlatformLocaleReader] implementation.
///
/// Defaults to [WidgetsBindingPlatformLocaleReader], which is safe for
/// production. Tests may override with a controlled fake.

final class PlatformReaderProvider
    extends
        $FunctionalProvider<
          PlatformLocaleReader,
          PlatformLocaleReader,
          PlatformLocaleReader
        >
    with $Provider<PlatformLocaleReader> {
  /// Provides the [PlatformLocaleReader] implementation.
  ///
  /// Defaults to [WidgetsBindingPlatformLocaleReader], which is safe for
  /// production. Tests may override with a controlled fake.
  PlatformReaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'platformReaderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$platformReaderHash();

  @$internal
  @override
  $ProviderElement<PlatformLocaleReader> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlatformLocaleReader create(Ref ref) {
    return platformReader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlatformLocaleReader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlatformLocaleReader>(value),
    );
  }
}

String _$platformReaderHash() => r'fa755b57c00704dd2fff2a08e03943c935a69065';

/// Manages the locale state machine for abigotado.dev.
///
/// Reads the initial locale from the [LocaleStore] and [PlatformLocaleReader],
/// applies user choices immediately (in-memory), and persists them
/// asynchronously. Persist failures are surfaced via [LocaleState.persistFailed]
/// rather than thrown to the UI.
///
/// Stub — logic implemented in the GREEN phase.

@ProviderFor(LocaleNotifier)
final localeProvider = LocaleNotifierProvider._();

/// Manages the locale state machine for abigotado.dev.
///
/// Reads the initial locale from the [LocaleStore] and [PlatformLocaleReader],
/// applies user choices immediately (in-memory), and persists them
/// asynchronously. Persist failures are surfaced via [LocaleState.persistFailed]
/// rather than thrown to the UI.
///
/// Stub — logic implemented in the GREEN phase.
final class LocaleNotifierProvider
    extends $NotifierProvider<LocaleNotifier, LocaleState> {
  /// Manages the locale state machine for abigotado.dev.
  ///
  /// Reads the initial locale from the [LocaleStore] and [PlatformLocaleReader],
  /// applies user choices immediately (in-memory), and persists them
  /// asynchronously. Persist failures are surfaced via [LocaleState.persistFailed]
  /// rather than thrown to the UI.
  ///
  /// Stub — logic implemented in the GREEN phase.
  LocaleNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localeNotifierHash();

  @$internal
  @override
  LocaleNotifier create() => LocaleNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocaleState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocaleState>(value),
    );
  }
}

String _$localeNotifierHash() => r'dc0ae46dc8ad5ff2838f5160c2069e9d09bcc2a1';

/// Manages the locale state machine for abigotado.dev.
///
/// Reads the initial locale from the [LocaleStore] and [PlatformLocaleReader],
/// applies user choices immediately (in-memory), and persists them
/// asynchronously. Persist failures are surfaced via [LocaleState.persistFailed]
/// rather than thrown to the UI.
///
/// Stub — logic implemented in the GREEN phase.

abstract class _$LocaleNotifier extends $Notifier<LocaleState> {
  LocaleState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LocaleState, LocaleState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LocaleState, LocaleState>,
              LocaleState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
