import 'package:abigotado_dev/src/app/state/scroll_spy_state.dart';
import 'package:abigotado_dev/src/app/widget/editor_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'scroll_spy_notifier.g.dart';

/// Manages the scroll-spy state for abigotado.dev.
///
/// Tracks which [EditorFile] section is currently active (visible in the
/// activation zone) and holds one-shot [ScrollRequest]s dispatched when the
/// user taps a sidebar row. The `EditorScrollHost` consumes both via
/// `ref.listen`.
@riverpod
class ScrollSpyNotifier extends _$ScrollSpyNotifier {
  /// Monotonically-increasing counter used to make consecutive requests to
  /// the same [EditorFile] produce distinct [ScrollRequest] values so that
  /// `ref.listen` re-fires on every tap.
  int _nextId = 0;

  @override
  ScrollSpyState build() => const ScrollSpyState();

  /// Updates [ScrollSpyState.activeFile] to [file].
  ///
  /// Called by the scroll host's `_onScroll` callback whenever the derived
  /// active section changes. No-ops if [file] is already active (Equatable
  /// guards against spurious rebuilds).
  void setActiveFile(EditorFile file) {
    if (file == state.activeFile) return;
    state = state.copyWith(activeFile: file);
  }

  /// Enqueues a one-shot scroll navigation request to [file].
  ///
  /// The scroll host listens for [ScrollSpyState.scrollRequest] changes
  /// and dispatches the scroll in response. Each call increments an
  /// internal counter so that two consecutive requests to the same file
  /// both fire.
  void requestScrollTo(EditorFile file) {
    state = state.copyWith(
      scrollRequest: ScrollRequest(target: file, id: ++_nextId),
    );
  }

  /// Clears the pending [ScrollSpyState.scrollRequest] after the host has
  /// dispatched the navigation, preventing a re-fire on rebuild.
  void clearScrollRequest() {
    if (state.scrollRequest == null) return;
    state = state.copyWith(scrollRequest: null);
  }

  /// Latches the scroll-reveal set to [next] (union with `alreadyRevealed` is
  /// done by the caller via `revealedSet`; this method stores the result).
  ///
  /// No-ops when [next] equals the current [ScrollSpyState.revealed] and
  /// [ScrollSpyState.hasMeasured] is already `true`, avoiding spurious
  /// rebuilds on every scroll frame once all sections are visible.
  ///
  /// (Green pass.)
  void revealSections(Set<EditorFile> next) {
    if (state.hasMeasured && setEquals(next, state.revealed)) return;
    state = state.copyWith(revealed: next, hasMeasured: true);
  }
}

/// Derives the currently active [EditorFile] from [scrollSpyProvider].
///
/// Widgets that only need the active file (e.g. `EditorSidebar`) watch this
/// thin selector rather than the full [ScrollSpyState], so they rebuild only
/// when the active file changes — not on every [ScrollRequest] update.
@riverpod
EditorFile activeEditorFileValue(Ref ref) =>
    ref.watch(scrollSpyProvider.select((s) => s.activeFile));

/// Returns `true` when [file]'s section has been revealed (or has never been
/// measured, in which case all sections default to visible so that content is
/// readable before the first scroll-spy tick).
///
/// `RevealOnScroll` watches this provider to drive its opacity/slide
/// animation. The `!hasMeasured` guard means sections show immediately on
/// first render — the host only starts managing reveal after its first
/// measurement pass, so there is never a "flash of hidden content" on load.
@riverpod
bool sectionRevealed(Ref ref, EditorFile file) {
  final state = ref.watch(scrollSpyProvider);
  return !state.hasMeasured || state.revealed.contains(file);
}
