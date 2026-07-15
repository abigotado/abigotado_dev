// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presentation_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives which [PresentationView] the pane shows: the stylized pitch or the
/// `README.md` document.
///
/// Deliberately simpler than `EffectsNotifier` or `LocaleNotifier`: there is
/// NO store and NO persistence — this is pure navigation state, always reset
/// to [PresentationView.pitch] on a fresh page load. The README is reached
/// via explicit entry points (chip, invitation card, sidebar row) and closed
/// via the browser-Back / close-button path documented on `openReadme` in
/// `readme_navigation.dart` — this notifier only flips the flag; it never
/// touches `Navigator` itself.
///
/// `keepAlive: true` — same rationale as `HotReloadNotifier`: an entry point
/// (`ReadmeEntryChip`, `ReadmeInvitationCard`) only ever `ref.read`s this
/// notifier from a tap callback; it never `ref.watch`es it. Without
/// `keepAlive`, a moment with zero active watchers (`PaneContent` and
/// `EditorSidebar` are the app's only watchers) would let auto-dispose
/// reclaim the state between the tap and the next read, silently reverting
/// `openReadme()` back to [PresentationView.pitch].

@ProviderFor(PresentationNotifier)
final presentationProvider = PresentationNotifierProvider._();

/// Drives which [PresentationView] the pane shows: the stylized pitch or the
/// `README.md` document.
///
/// Deliberately simpler than `EffectsNotifier` or `LocaleNotifier`: there is
/// NO store and NO persistence — this is pure navigation state, always reset
/// to [PresentationView.pitch] on a fresh page load. The README is reached
/// via explicit entry points (chip, invitation card, sidebar row) and closed
/// via the browser-Back / close-button path documented on `openReadme` in
/// `readme_navigation.dart` — this notifier only flips the flag; it never
/// touches `Navigator` itself.
///
/// `keepAlive: true` — same rationale as `HotReloadNotifier`: an entry point
/// (`ReadmeEntryChip`, `ReadmeInvitationCard`) only ever `ref.read`s this
/// notifier from a tap callback; it never `ref.watch`es it. Without
/// `keepAlive`, a moment with zero active watchers (`PaneContent` and
/// `EditorSidebar` are the app's only watchers) would let auto-dispose
/// reclaim the state between the tap and the next read, silently reverting
/// `openReadme()` back to [PresentationView.pitch].
final class PresentationNotifierProvider
    extends $NotifierProvider<PresentationNotifier, PresentationState> {
  /// Drives which [PresentationView] the pane shows: the stylized pitch or the
  /// `README.md` document.
  ///
  /// Deliberately simpler than `EffectsNotifier` or `LocaleNotifier`: there is
  /// NO store and NO persistence — this is pure navigation state, always reset
  /// to [PresentationView.pitch] on a fresh page load. The README is reached
  /// via explicit entry points (chip, invitation card, sidebar row) and closed
  /// via the browser-Back / close-button path documented on `openReadme` in
  /// `readme_navigation.dart` — this notifier only flips the flag; it never
  /// touches `Navigator` itself.
  ///
  /// `keepAlive: true` — same rationale as `HotReloadNotifier`: an entry point
  /// (`ReadmeEntryChip`, `ReadmeInvitationCard`) only ever `ref.read`s this
  /// notifier from a tap callback; it never `ref.watch`es it. Without
  /// `keepAlive`, a moment with zero active watchers (`PaneContent` and
  /// `EditorSidebar` are the app's only watchers) would let auto-dispose
  /// reclaim the state between the tap and the next read, silently reverting
  /// `openReadme()` back to [PresentationView.pitch].
  PresentationNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'presentationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$presentationNotifierHash();

  @$internal
  @override
  PresentationNotifier create() => PresentationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PresentationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PresentationState>(value),
    );
  }
}

String _$presentationNotifierHash() =>
    r'50417f6f7120d5e0484906faef2afc6260259835';

/// Drives which [PresentationView] the pane shows: the stylized pitch or the
/// `README.md` document.
///
/// Deliberately simpler than `EffectsNotifier` or `LocaleNotifier`: there is
/// NO store and NO persistence — this is pure navigation state, always reset
/// to [PresentationView.pitch] on a fresh page load. The README is reached
/// via explicit entry points (chip, invitation card, sidebar row) and closed
/// via the browser-Back / close-button path documented on `openReadme` in
/// `readme_navigation.dart` — this notifier only flips the flag; it never
/// touches `Navigator` itself.
///
/// `keepAlive: true` — same rationale as `HotReloadNotifier`: an entry point
/// (`ReadmeEntryChip`, `ReadmeInvitationCard`) only ever `ref.read`s this
/// notifier from a tap callback; it never `ref.watch`es it. Without
/// `keepAlive`, a moment with zero active watchers (`PaneContent` and
/// `EditorSidebar` are the app's only watchers) would let auto-dispose
/// reclaim the state between the tap and the next read, silently reverting
/// `openReadme()` back to [PresentationView.pitch].

abstract class _$PresentationNotifier extends $Notifier<PresentationState> {
  PresentationState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PresentationState, PresentationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PresentationState, PresentationState>,
              PresentationState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Whether the `README.md` document is currently the shown presentation.
///
/// A thin `.select` over [presentationProvider] so widgets that only need
/// this boolean (sidebar rows, the FAB visibility, `PaneContent`) rebuild
/// only when the presentation actually flips, not on unrelated state changes.

@ProviderFor(readmeOpen)
final readmeOpenProvider = ReadmeOpenProvider._();

/// Whether the `README.md` document is currently the shown presentation.
///
/// A thin `.select` over [presentationProvider] so widgets that only need
/// this boolean (sidebar rows, the FAB visibility, `PaneContent`) rebuild
/// only when the presentation actually flips, not on unrelated state changes.

final class ReadmeOpenProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the `README.md` document is currently the shown presentation.
  ///
  /// A thin `.select` over [presentationProvider] so widgets that only need
  /// this boolean (sidebar rows, the FAB visibility, `PaneContent`) rebuild
  /// only when the presentation actually flips, not on unrelated state changes.
  ReadmeOpenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'readmeOpenProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$readmeOpenHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return readmeOpen(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$readmeOpenHash() => r'14d9f61825fcf91fdeaa16a0907471111c21fec5';
