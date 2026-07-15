import 'package:abigotado_dev/src/app/view/editor_scroll_host.dart';
import 'package:abigotado_dev/src/features/readme/state/presentation_notifier.dart';
import 'package:abigotado_dev/src/features/readme/view/readme_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selects which presentation fills the editor content pane.
///
/// Switches between [EditorScrollHost] (the pitch) and [ReadmeView] (the
/// README document) based on [readmeOpenProvider]. This is a structural swap,
/// not an overlay: [EditorScrollHost] fully unmounts while the README is
/// open.
///
/// ### Stage-1 decision: unmount, don't preserve scroll offset
///
/// Unmounting [EditorScrollHost] means its `ScrollController` is disposed —
/// the pitch's scroll offset resets to the top when the user returns from the
/// README. This is INTENTIONAL for stage 1: the README is a modal-ish
/// takeover of the pane (the tab title, the browser-Back arm via
/// `openReadme`, and the ✕ close all read as "you left the pitch and came
/// back"), and any return-to-pitch path that matters (a sidebar tap while the
/// README is open) already re-requests a scroll target via
/// `ScrollSpyNotifier.requestScrollTo`, so the visible offset is correct on
/// arrival regardless of where the scroll position happened to reset to.
///
/// An `IndexedStack` + `TickerMode` approach that keeps both trees mounted
/// (preserving the exact scroll pixel) was considered and explicitly
/// rejected here: it would keep `EditorScrollHost`'s scroll listener,
/// `NotificationListener<ScrollMetricsNotification>`, and reveal-latch logic
/// alive (and thus paying their per-frame cost) the entire time the README is
/// open, for a preservation guarantee stage 1 doesn't need. Revisit if a
/// later stage's UX review calls for it.
class PaneContent extends ConsumerWidget {
  /// Creates the pane-content switch.
  const PaneContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(readmeOpenProvider)) {
      false => const EditorScrollHost(),
      true => const ReadmeView(),
    };
  }
}
