import 'package:abigotado_dev/src/app/state/scroll_spy_state.dart';
import 'package:abigotado_dev/src/app/widget/editor_file.dart';
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
}

/// Derives the currently active [EditorFile] from [scrollSpyProvider].
///
/// Widgets that only need the active file (e.g. `EditorSidebar`) watch this
/// thin selector rather than the full [ScrollSpyState], so they rebuild only
/// when the active file changes — not on every [ScrollRequest] update.
@riverpod
EditorFile activeEditorFileValue(Ref ref) =>
    ref.watch(scrollSpyProvider.select((s) => s.activeFile));
