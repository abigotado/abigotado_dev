import 'dart:async';

import 'package:abigotado_dev/src/app/state/scroll_spy_notifier.dart';
import 'package:abigotado_dev/src/app/state/scroll_spy_state.dart';
import 'package:abigotado_dev/src/app/view/landing_page.dart';
import 'package:abigotado_dev/src/app/view/reveal_geometry.dart';
import 'package:abigotado_dev/src/app/view/scroll_spy_geometry.dart';
import 'package:abigotado_dev/src/app/widget/editor_file.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The scroll host for the landing page.
///
/// Owns the shared [ScrollController] and per-section [GlobalKey] map, and
/// passes them into [LandingPage] so the scroll-spy logic can measure section
/// positions. Sits between the editor shell and pane in the widget tree.
///
/// Scroll-spy logic: on every scroll frame `_updateActive` measures section
/// offsets live via `RenderAbstractViewport.getOffsetToReveal` — there is no
/// offset cache. Live measurement is correct under any reflow (hero animation,
/// locale switch, window resize) because the geometry is always fresh.
///
/// Re-derive triggers:
/// - `initState` schedules the first post-frame call so the highlight is
///   correct before the user scrolls.
/// - `ScrollController.addListener(_onScroll)` fires on every scroll frame.
/// - `NotificationListener<ScrollMetricsNotification>` fires whenever content
///   or viewport dimensions change (hero animation shrink, locale text reflow,
///   window resize) — this is the single trigger for the stationary case and
///   subsumes the previous locale-listen and LayoutBuilder approaches.
///
/// Sidebar taps trigger [ScrollSpyNotifier.requestScrollTo] and the host
/// animates (or jumps, in lite mode) to the target.
class EditorScrollHost extends ConsumerStatefulWidget {
  /// Creates the editor scroll host.
  const EditorScrollHost({super.key});

  @override
  ConsumerState<EditorScrollHost> createState() => _EditorScrollHostState();
}

class _EditorScrollHostState extends ConsumerState<EditorScrollHost> {
  final ScrollController _controller = ScrollController();

  /// One [GlobalKey] per [EditorFile], used to locate section positions in
  /// the scroll-content coordinate space.
  final Map<EditorFile, GlobalKey> _sectionKeys = {
    for (final f in EditorFile.values) f: GlobalKey(),
  };

  /// Guards against scheduling multiple post-frame [_updateActive] callbacks
  /// in the same frame (coalesces scroll-metrics and scroll triggers).
  bool _updateScheduled = false;

  /// Effective effects mode, captured in [build] so that the scroll-request
  /// handler can read it synchronously without a provider access inside a
  /// callback.
  late EffectsMode _mode;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    // Schedule the first active-file derivation after the initial layout so
    // that the sidebar highlight is correct before the user scrolls.
    _scheduleUpdate();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Capture the effective mode on every build so the scroll-request handler
    // can read it without a provider look-up inside an async callback.
    _mode = effectsModeOf(context, ref);

    // Listen for sidebar tap requests.
    ref.listen<ScrollRequest?>(
      scrollSpyProvider.select((s) => s.scrollRequest),
      _onScrollRequest,
    );

    // ScrollMetricsNotification fires whenever content or viewport dimensions
    // change — hero animation shrink, locale text reflow, window resize — so
    // it is the single correct trigger for the stationary re-derive case.
    // The notification is dispatched from a microtask AFTER the frame's layout
    // completes (SDK asserts schedulerPhase != persistentCallbacks), so render
    // objects are laid out and we are between frames — calling _updateActive()
    // directly is safe and avoids the addPostFrameCallback round-trip that
    // would otherwise leave the highlight stale in an otherwise-idle app.
    // Returning false lets the notification continue bubbling.
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (_) {
        _updateActive();
        return false;
      },
      child: SingleChildScrollView(
        controller: _controller,
        child: LandingPage(sectionKeys: _sectionKeys),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Post-frame update scheduling
  // ---------------------------------------------------------------------------

  /// Coalesces multiple triggers per frame into a single post-frame
  /// [_updateActive] call. Used for the stationary cases (initState, hero
  /// animation, locale reflow, viewport resize) where a scroll event alone
  /// would not fire but the highlight still needs to be re-derived.
  void _scheduleUpdate() {
    if (_updateScheduled) return;
    _updateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScheduled = false;
      if (!mounted) return;
      _updateActive();
    });
  }

  // ---------------------------------------------------------------------------
  // Scroll-spy
  // ---------------------------------------------------------------------------

  /// Called by [ScrollController] on every scroll frame.
  void _onScroll() => _updateActive();

  /// Derives the active [EditorFile] from the current scroll position and
  /// notifies [ScrollSpyNotifier] when it changes.
  ///
  /// Measures section offsets LIVE on every call via
  /// `RenderAbstractViewport.getOffsetToReveal` — there is no cache. This
  /// ensures correctness under any reflow (hero animation changing height,
  /// locale switch, window resize) because the geometry is always fresh.
  /// 5 sections × one `getOffsetToReveal` call per frame is negligible.
  ///
  /// Guards against being called before first layout: requires
  /// [ScrollPosition.haveDimensions] and at least one attached render object.
  void _updateActive() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    // haveDimensions prevents reading maxScrollExtent before first layout,
    // which would spuriously bottom-pin to sections.last.
    if (!position.haveDimensions) return;

    // Build the document-ordered sections list live, measuring each section's
    // top offset in scroll-content pixels from its render object. Skip any
    // section whose render object is not yet attached.
    final sections = <({EditorFile file, double offset})>[];
    for (final file in EditorFile.values) {
      final ctx = _sectionKeys[file]?.currentContext;
      if (ctx == null) continue;
      final ro = ctx.findRenderObject();
      if (ro == null || !ro.attached) continue;
      final offset = RenderAbstractViewport.of(
        ro,
      ).getOffsetToReveal(ro, 0).offset;
      sections.add((file: file, offset: offset));
    }
    if (sections.isEmpty) return;

    final next = activeEditorFile(
      sections: sections,
      scrollOffset: _controller.offset,
      maxScrollExtent: position.maxScrollExtent,
    );
    // The notifier early-outs when the value is unchanged, so calling this on
    // every scroll frame does not produce a rebuild storm.
    ref.read(scrollSpyProvider.notifier).setActiveFile(next);

    // Scroll-reveal: latch sections that have crossed the reveal line.
    // Skipped in lite so hasMeasured stays false and every section renders
    // revealed (zero tickers). Reuses the same measured `sections` + live
    // position as scroll-spy.
    if (_mode != EffectsMode.lite) {
      ref
          .read(scrollSpyProvider.notifier)
          .revealSections(
            revealedSet(
              sections: sections,
              scrollOffset: _controller.offset,
              viewportHeight: _controller.position.viewportDimension,
              alreadyRevealed: ref.read(scrollSpyProvider).revealed,
            ),
          );
    }
  }

  // ---------------------------------------------------------------------------
  // Tap-to-scroll
  // ---------------------------------------------------------------------------

  /// Called when a new [ScrollRequest] is dispatched (e.g. sidebar tap).
  ///
  /// Lite mode uses [Duration.zero] so `ensureVisible` calls `jumpTo`
  /// internally — no animation ticker is scheduled. Full mode uses a 320 ms
  /// ease so the scroll is animated (schedules a transient ticker). This
  /// asymmetry is the FIX-3 reduced-motion guarantee.
  void _onScrollRequest(ScrollRequest? prev, ScrollRequest? next) {
    if (next == null) return;

    final ctx = _sectionKeys[next.target]?.currentContext;
    if (ctx == null) {
      ref.read(scrollSpyProvider.notifier).clearScrollRequest();
      return;
    }

    unawaited(
      Scrollable.ensureVisible(
        ctx,
        duration: _mode == EffectsMode.lite
            ? Duration.zero
            : const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      ),
    );

    ref.read(scrollSpyProvider.notifier).clearScrollRequest();
  }
}
