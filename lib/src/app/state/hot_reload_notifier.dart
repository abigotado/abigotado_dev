import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'hot_reload_notifier.g.dart';

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
@Riverpod(keepAlive: true)
class HotReloadNotifier extends _$HotReloadNotifier {
  /// The initial pulse id. `0` means "no pulse has fired yet".
  @override
  int build() => 0;

  /// Bumps the pulse id, triggering a fresh section-flash wave.
  ///
  /// Each call yields a distinct id so repeated FAB taps re-fire the wave.
  void pulse() => state = state + 1;
}
