// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hot_reload_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Coordinates the hot-reload "rebuild" pulse across the page sections.
///
/// The state is a monotonically-increasing pulse id. [pulse] bumps it on every
/// hot-reload FAB tap so each `SectionFlash` wrapper — which watches the id —
/// re-fires its flash wave even on repeated taps (a new id is always distinct,
/// so watchers diff it). Mirrors the monotonic-id one-shot idiom established by
/// `ScrollSpyNotifier` / `ScrollRequest`.
///
/// `keepAlive: true` so the monotonic counter is never reset by auto-dispose
/// when momentarily unwatched — a reset would re-fire a stale pulse id or
/// silently swallow a tap. The whole-app `SectionFlash`/FAB watchers normally
/// keep it alive anyway; this makes the invariant explicit and robust.

@ProviderFor(HotReloadNotifier)
final hotReloadProvider = HotReloadNotifierProvider._();

/// Coordinates the hot-reload "rebuild" pulse across the page sections.
///
/// The state is a monotonically-increasing pulse id. [pulse] bumps it on every
/// hot-reload FAB tap so each `SectionFlash` wrapper — which watches the id —
/// re-fires its flash wave even on repeated taps (a new id is always distinct,
/// so watchers diff it). Mirrors the monotonic-id one-shot idiom established by
/// `ScrollSpyNotifier` / `ScrollRequest`.
///
/// `keepAlive: true` so the monotonic counter is never reset by auto-dispose
/// when momentarily unwatched — a reset would re-fire a stale pulse id or
/// silently swallow a tap. The whole-app `SectionFlash`/FAB watchers normally
/// keep it alive anyway; this makes the invariant explicit and robust.
final class HotReloadNotifierProvider
    extends $NotifierProvider<HotReloadNotifier, int> {
  /// Coordinates the hot-reload "rebuild" pulse across the page sections.
  ///
  /// The state is a monotonically-increasing pulse id. [pulse] bumps it on every
  /// hot-reload FAB tap so each `SectionFlash` wrapper — which watches the id —
  /// re-fires its flash wave even on repeated taps (a new id is always distinct,
  /// so watchers diff it). Mirrors the monotonic-id one-shot idiom established by
  /// `ScrollSpyNotifier` / `ScrollRequest`.
  ///
  /// `keepAlive: true` so the monotonic counter is never reset by auto-dispose
  /// when momentarily unwatched — a reset would re-fire a stale pulse id or
  /// silently swallow a tap. The whole-app `SectionFlash`/FAB watchers normally
  /// keep it alive anyway; this makes the invariant explicit and robust.
  HotReloadNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hotReloadProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hotReloadNotifierHash();

  @$internal
  @override
  HotReloadNotifier create() => HotReloadNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$hotReloadNotifierHash() => r'3510311fa2ff459ee49f039f5b73cb2af5f03cec';

/// Coordinates the hot-reload "rebuild" pulse across the page sections.
///
/// The state is a monotonically-increasing pulse id. [pulse] bumps it on every
/// hot-reload FAB tap so each `SectionFlash` wrapper — which watches the id —
/// re-fires its flash wave even on repeated taps (a new id is always distinct,
/// so watchers diff it). Mirrors the monotonic-id one-shot idiom established by
/// `ScrollSpyNotifier` / `ScrollRequest`.
///
/// `keepAlive: true` so the monotonic counter is never reset by auto-dispose
/// when momentarily unwatched — a reset would re-fire a stale pulse id or
/// silently swallow a tap. The whole-app `SectionFlash`/FAB watchers normally
/// keep it alive anyway; this makes the invariant explicit and robust.

abstract class _$HotReloadNotifier extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
