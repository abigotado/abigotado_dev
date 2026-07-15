import 'package:abigotado_dev/src/features/readme/state/presentation_state.dart';
import 'package:abigotado_dev/src/features/readme/state/presentation_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'presentation_notifier.g.dart';

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
@Riverpod(keepAlive: true)
class PresentationNotifier extends _$PresentationNotifier {
  @override
  PresentationState build() => const PresentationState();

  /// Switches the presentation to [PresentationView.readme].
  ///
  /// No-ops if the README is already open (double-entry guard) — the sole
  /// caller is `openReadme` in `readme_navigation.dart`, which pairs this with
  /// arming the browser-Back interception; calling it twice must never arm a
  /// second `LocalHistoryEntry`.
  void openReadme() {
    if (state.view == PresentationView.readme) return;
    state = state.copyWith(view: PresentationView.readme);
  }

  /// Switches the presentation back to [PresentationView.pitch].
  ///
  /// No-ops if the pitch is already shown. The ONLY caller is the
  /// `LocalHistoryEntry.onRemove` callback armed by `openReadme` — every UI
  /// close path (✕ button, sidebar tap) calls
  /// `Navigator.of(context).maybePop()` instead of this method directly, so
  /// the local history entry is always popped in lockstep with the
  /// presentation state.
  void showPitch() {
    if (state.view == PresentationView.pitch) return;
    state = state.copyWith(view: PresentationView.pitch);
  }
}

/// Whether the `README.md` document is currently the shown presentation.
///
/// A thin `.select` over [presentationProvider] so widgets that only need
/// this boolean (sidebar rows, the FAB visibility, `PaneContent`) rebuild
/// only when the presentation actually flips, not on unrelated state changes.
@riverpod
bool readmeOpen(Ref ref) => ref.watch(
  presentationProvider.select((s) => s.view == PresentationView.readme),
);
