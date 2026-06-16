// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'effects_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the [EffectsStore] implementation.
///
/// Must be overridden at the [ProviderScope] root before the app starts —
/// see `main.dart`. Test suites override it with a fake or in-memory store.

@ProviderFor(effectsStore)
final effectsStoreProvider = EffectsStoreProvider._();

/// Provides the [EffectsStore] implementation.
///
/// Must be overridden at the [ProviderScope] root before the app starts —
/// see `main.dart`. Test suites override it with a fake or in-memory store.

final class EffectsStoreProvider
    extends $FunctionalProvider<EffectsStore, EffectsStore, EffectsStore>
    with $Provider<EffectsStore> {
  /// Provides the [EffectsStore] implementation.
  ///
  /// Must be overridden at the [ProviderScope] root before the app starts —
  /// see `main.dart`. Test suites override it with a fake or in-memory store.
  EffectsStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'effectsStoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$effectsStoreHash();

  @$internal
  @override
  $ProviderElement<EffectsStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EffectsStore create(Ref ref) {
    return effectsStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EffectsStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EffectsStore>(value),
    );
  }
}

String _$effectsStoreHash() => r'bc4064ef0f5aae2a3a7e451b99fbaac7c007b5f7';

/// Manages the effects-mode state for abigotado.dev.
///
/// Reads the initial manual choice from the [EffectsStore] on startup.
/// Effective mode (full vs lite) is resolved at the widget layer via
/// [effectsModeOf], which combines the manual choice with OS reduced-motion
/// and viewport-width signals.
///
/// Persist failures are surfaced via [EffectsState.persistFailed] rather
/// than thrown to the UI.

@ProviderFor(EffectsNotifier)
final effectsProvider = EffectsNotifierProvider._();

/// Manages the effects-mode state for abigotado.dev.
///
/// Reads the initial manual choice from the [EffectsStore] on startup.
/// Effective mode (full vs lite) is resolved at the widget layer via
/// [effectsModeOf], which combines the manual choice with OS reduced-motion
/// and viewport-width signals.
///
/// Persist failures are surfaced via [EffectsState.persistFailed] rather
/// than thrown to the UI.
final class EffectsNotifierProvider
    extends $NotifierProvider<EffectsNotifier, EffectsState> {
  /// Manages the effects-mode state for abigotado.dev.
  ///
  /// Reads the initial manual choice from the [EffectsStore] on startup.
  /// Effective mode (full vs lite) is resolved at the widget layer via
  /// [effectsModeOf], which combines the manual choice with OS reduced-motion
  /// and viewport-width signals.
  ///
  /// Persist failures are surfaced via [EffectsState.persistFailed] rather
  /// than thrown to the UI.
  EffectsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'effectsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$effectsNotifierHash();

  @$internal
  @override
  EffectsNotifier create() => EffectsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EffectsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EffectsState>(value),
    );
  }
}

String _$effectsNotifierHash() => r'f0781b381e6ec29a41396184f7ab30585c9638b3';

/// Manages the effects-mode state for abigotado.dev.
///
/// Reads the initial manual choice from the [EffectsStore] on startup.
/// Effective mode (full vs lite) is resolved at the widget layer via
/// [effectsModeOf], which combines the manual choice with OS reduced-motion
/// and viewport-width signals.
///
/// Persist failures are surfaced via [EffectsState.persistFailed] rather
/// than thrown to the UI.

abstract class _$EffectsNotifier extends $Notifier<EffectsState> {
  EffectsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EffectsState, EffectsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EffectsState, EffectsState>,
              EffectsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
