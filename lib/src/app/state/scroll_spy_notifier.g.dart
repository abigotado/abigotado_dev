// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scroll_spy_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the scroll-spy state for abigotado.dev.
///
/// Tracks which [EditorFile] section is currently active (visible in the
/// activation zone) and holds one-shot [ScrollRequest]s dispatched when the
/// user taps a sidebar row. The `EditorScrollHost` consumes both via
/// `ref.listen`.

@ProviderFor(ScrollSpyNotifier)
final scrollSpyProvider = ScrollSpyNotifierProvider._();

/// Manages the scroll-spy state for abigotado.dev.
///
/// Tracks which [EditorFile] section is currently active (visible in the
/// activation zone) and holds one-shot [ScrollRequest]s dispatched when the
/// user taps a sidebar row. The `EditorScrollHost` consumes both via
/// `ref.listen`.
final class ScrollSpyNotifierProvider
    extends $NotifierProvider<ScrollSpyNotifier, ScrollSpyState> {
  /// Manages the scroll-spy state for abigotado.dev.
  ///
  /// Tracks which [EditorFile] section is currently active (visible in the
  /// activation zone) and holds one-shot [ScrollRequest]s dispatched when the
  /// user taps a sidebar row. The `EditorScrollHost` consumes both via
  /// `ref.listen`.
  ScrollSpyNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scrollSpyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scrollSpyNotifierHash();

  @$internal
  @override
  ScrollSpyNotifier create() => ScrollSpyNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScrollSpyState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScrollSpyState>(value),
    );
  }
}

String _$scrollSpyNotifierHash() => r'679f544659889ecc9f3f50ae15f6790870ff0a87';

/// Manages the scroll-spy state for abigotado.dev.
///
/// Tracks which [EditorFile] section is currently active (visible in the
/// activation zone) and holds one-shot [ScrollRequest]s dispatched when the
/// user taps a sidebar row. The `EditorScrollHost` consumes both via
/// `ref.listen`.

abstract class _$ScrollSpyNotifier extends $Notifier<ScrollSpyState> {
  ScrollSpyState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ScrollSpyState, ScrollSpyState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ScrollSpyState, ScrollSpyState>,
              ScrollSpyState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Derives the currently active [EditorFile] from [scrollSpyProvider].
///
/// Widgets that only need the active file (e.g. `EditorSidebar`) watch this
/// thin selector rather than the full [ScrollSpyState], so they rebuild only
/// when the active file changes — not on every [ScrollRequest] update.

@ProviderFor(activeEditorFileValue)
final activeEditorFileValueProvider = ActiveEditorFileValueProvider._();

/// Derives the currently active [EditorFile] from [scrollSpyProvider].
///
/// Widgets that only need the active file (e.g. `EditorSidebar`) watch this
/// thin selector rather than the full [ScrollSpyState], so they rebuild only
/// when the active file changes — not on every [ScrollRequest] update.

final class ActiveEditorFileValueProvider
    extends $FunctionalProvider<EditorFile, EditorFile, EditorFile>
    with $Provider<EditorFile> {
  /// Derives the currently active [EditorFile] from [scrollSpyProvider].
  ///
  /// Widgets that only need the active file (e.g. `EditorSidebar`) watch this
  /// thin selector rather than the full [ScrollSpyState], so they rebuild only
  /// when the active file changes — not on every [ScrollRequest] update.
  ActiveEditorFileValueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeEditorFileValueProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeEditorFileValueHash();

  @$internal
  @override
  $ProviderElement<EditorFile> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EditorFile create(Ref ref) {
    return activeEditorFileValue(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EditorFile value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EditorFile>(value),
    );
  }
}

String _$activeEditorFileValueHash() =>
    r'97992428b61dbe25c12125a3b7c54b37af387e54';

/// Returns `true` when [file]'s section has been revealed (or has never been
/// measured, in which case all sections default to visible so that content is
/// readable before the first scroll-spy tick).
///
/// `RevealOnScroll` watches this provider to drive its opacity/slide
/// animation. The `!hasMeasured` guard means sections show immediately on
/// first render — the host only starts managing reveal after its first
/// measurement pass, so there is never a "flash of hidden content" on load.

@ProviderFor(sectionRevealed)
final sectionRevealedProvider = SectionRevealedFamily._();

/// Returns `true` when [file]'s section has been revealed (or has never been
/// measured, in which case all sections default to visible so that content is
/// readable before the first scroll-spy tick).
///
/// `RevealOnScroll` watches this provider to drive its opacity/slide
/// animation. The `!hasMeasured` guard means sections show immediately on
/// first render — the host only starts managing reveal after its first
/// measurement pass, so there is never a "flash of hidden content" on load.

final class SectionRevealedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Returns `true` when [file]'s section has been revealed (or has never been
  /// measured, in which case all sections default to visible so that content is
  /// readable before the first scroll-spy tick).
  ///
  /// `RevealOnScroll` watches this provider to drive its opacity/slide
  /// animation. The `!hasMeasured` guard means sections show immediately on
  /// first render — the host only starts managing reveal after its first
  /// measurement pass, so there is never a "flash of hidden content" on load.
  SectionRevealedProvider._({
    required SectionRevealedFamily super.from,
    required EditorFile super.argument,
  }) : super(
         retry: null,
         name: r'sectionRevealedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sectionRevealedHash();

  @override
  String toString() {
    return r'sectionRevealedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as EditorFile;
    return sectionRevealed(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SectionRevealedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sectionRevealedHash() => r'1688f400cae9ea91cf3bf938f7430311887e0b29';

/// Returns `true` when [file]'s section has been revealed (or has never been
/// measured, in which case all sections default to visible so that content is
/// readable before the first scroll-spy tick).
///
/// `RevealOnScroll` watches this provider to drive its opacity/slide
/// animation. The `!hasMeasured` guard means sections show immediately on
/// first render — the host only starts managing reveal after its first
/// measurement pass, so there is never a "flash of hidden content" on load.

final class SectionRevealedFamily extends $Family
    with $FunctionalFamilyOverride<bool, EditorFile> {
  SectionRevealedFamily._()
    : super(
        retry: null,
        name: r'sectionRevealedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Returns `true` when [file]'s section has been revealed (or has never been
  /// measured, in which case all sections default to visible so that content is
  /// readable before the first scroll-spy tick).
  ///
  /// `RevealOnScroll` watches this provider to drive its opacity/slide
  /// animation. The `!hasMeasured` guard means sections show immediately on
  /// first render — the host only starts managing reveal after its first
  /// measurement pass, so there is never a "flash of hidden content" on load.

  SectionRevealedProvider call(EditorFile file) =>
      SectionRevealedProvider._(argument: file, from: this);

  @override
  String toString() => r'sectionRevealedProvider';
}
