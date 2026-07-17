import 'dart:async';

import 'package:abigotado_dev/src/app/state/scroll_spy_notifier.dart';
import 'package:abigotado_dev/src/app/widget/editor_file.dart';
import 'package:abigotado_dev/src/app/widget/reveal/section_build_scope.dart';
import 'package:abigotado_dev/src/app/widget/reveal/section_build_timing.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps [child] in the "section build" reveal — the effect that replaces
/// `RevealOnScroll`'s plain fade+slide for the metrics/pubspec/changelog/
/// contacts sections: instead of just appearing, the section renders as if
/// the agent pipeline is assembling it live (chrome fades in, the heading
/// types itself out, then its content cascades in), mirroring the hero's
/// planner → coder → reviewer conceit at the section level.
///
/// ## Intended GREEN render (implemented in the green pass)
///
/// ```dart
/// // Mode is read PER BUILD — the RevealOnScroll / MergeCtaSection
/// // precedent, NOT TerminalHero's deliberate once-at-mount exception — so a
/// // mid-session effects toggle is honored immediately.
/// final mode = effectsModeOf(context, ref);
///
/// if (mode == EffectsMode.lite) {
///   // A full → lite flip disposes any in-flight controller: zero tickers,
///   // no scope, `child` renders through its own static branches.
///   _controller?.dispose();
///   _controller = null;
///   return widget.child;
/// }
///
/// // Full mode: lazily create the controller ONCE. The field is nullable
/// // but the instance, once created, is never replaced for the life of this
/// // State — SectionBuildScope's descendants depend on that identity being
/// // stable (see its class doc).
/// final controller = _controller ??= AnimationController(
///   vsync: this,
///   duration: const Duration(milliseconds: kSectionBuildMs),
/// );
///
/// final revealed = ref.watch(sectionRevealedProvider(widget.file));
/// _syncToRevealed(revealed, controller); // see below
///
/// return IgnorePointer(
///   ignoring: !revealed,
///   child: AnimatedBuilder(
///     animation: controller,
///     builder: (context, child) => Opacity(
///       opacity: chromeOpacity(controller.value),
///       // Load-bearing: RenderOpacity excludes semantics at opacity 0
///       // unless told otherwise — the same footgun `reveal_on_scroll.dart`
///       // already hit. Without this, an unrevealed section would drop out
///       // of the accessibility tree instead of merely gating its pointers.
///       alwaysIncludeSemantics: true,
///       child: SectionBuildScope(progress: controller, child: child!),
///     ),
///     child: widget.child,
///   ),
/// );
/// ```
///
/// ### Latch wiring — reacting to `sectionRevealedProvider(file)` edges
///
/// - **Boot** (`!hasMeasured`, so `sectionRevealedProvider` reports `true`
///   for every section before the host's first measurement pass):
///   `controller.value = 1` — the section renders already-built, with no
///   "typing" replay flashing on first paint.
/// - **`true → false`**: the ONE-TIME edge where a section's real
///   (measured) state turns out to be off-screen after the boot default of
///   `true`. A HARD JUMP — `controller.value = 0` — **never** `reverse()`:
///   an on-screen, already-built, bottom-band section must not visibly
///   *un-build* itself out from under the user.
/// - **`false → true`**: the section crosses the reveal line for real.
///   `controller.forward(from: 0)`, deferred to a post-frame callback
///   (`WidgetsBinding.instance.addPostFrameCallback`, guarded by `mounted`)
///   so the ticker never starts mid-frame on the very scroll frame that
///   latched `revealed`.
/// - **Already latched** (`revealed` stays `true` across rebuilds): a no-op
///   — the build never replays once played.
///
/// ### Rendering
///
/// [IgnorePointer] gates on `!revealed`, **not** on build completion —
/// pointers are LIVE for the whole ~800 ms build, matching
/// `reveal_on_scroll.dart`'s contract that a revealed section is
/// immediately interactive. [AnimatedBuilder] applies the base chrome fade
/// (`Opacity(chromeOpacity(t))`) and publishes `controller` itself via
/// `SectionBuildScope` so `TypeOnHeading`/`BuildCascadeItem` beneath [child]
/// can render their own animated affordances without this widget knowing
/// anything about headings or cascades.
///
/// ### End state
///
/// Once `controller` completes, it stops scheduling frames — zero transient
/// callbacks — and sits at value `1.0` forever (until this widget is
/// disposed or flips to lite). At that fixed value every timing function in
/// `section_build_timing.dart` returns its "done" endpoint
/// (`chromeOpacity(1) == 1`, cascade items at full opacity/zero offset, the
/// heading fully typed with its cursor hidden), so the completed render is
/// byte-for-byte identical to a plain static render of [child] — this is
/// exactly what makes the static branches of `TypeOnHeading` and
/// `BuildCascadeItem` safe to pixel-pin with goldens independent of this
/// widget's animated path.
///
/// ## THIS PASS
///
/// [_RevealBuildState.build] is the full "Intended GREEN render" above
/// (GREEN pass): mode is resolved per build, the controller is lazily
/// created once in full mode and disposed on a flip to lite, and
/// [_RevealBuildState._syncToRevealed] implements the four latch-edge cases
/// documented above.
class RevealBuild extends ConsumerStatefulWidget {
  /// Creates a section-build reveal wrapper for [child] keyed to [file].
  const RevealBuild({
    required this.file,
    required this.child,
    super.key,
  });

  /// The [EditorFile] whose reveal state drives this wrapper.
  final EditorFile file;

  /// The widget that will be revealed.
  final Widget child;

  @override
  ConsumerState<RevealBuild> createState() => _RevealBuildState();
}

class _RevealBuildState extends ConsumerState<RevealBuild>
    with TickerProviderStateMixin {
  // Not SingleTickerProviderStateMixin: a full → lite → full round trip
  // disposes and later re-creates the controller, and Single... only ever
  // permits vending one ticker for the life of the State — see
  // `LivingBackground`, which hits the same constraint for the same reason.
  AnimationController? _controller;

  // `null` means "not yet synced to a revealed value" — true at boot and
  // again immediately after a lite flip discards the controller. The first
  // sync after either takes the "boot" branch below rather than an edge.
  bool? _lastRevealed;

  /// Reconciles [controller] to a [revealed] value read this build, per the
  /// class doc's "Latch wiring" section.
  void _syncToRevealed(bool revealed, AnimationController controller) {
    final last = _lastRevealed;
    _lastRevealed = revealed;
    if (last == null) {
      // Boot (or first full-mode build after a lite round trip): render
      // already-settled with no replay, whichever way `revealed` sits.
      controller.value = revealed ? 1 : 0;
      return;
    }
    if (last == revealed) return; // Already latched — never replay.
    if (revealed) {
      // false → true: defer to a post-frame callback so the ticker never
      // starts mid-frame on the scroll frame that latched `revealed`.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(controller.forward(from: 0));
      });
    } else {
      // true → false: hard jump, never reverse() — an already-built section
      // must not visibly un-build itself out from under the user.
      controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = effectsModeOf(context, ref);
    if (mode == EffectsMode.lite) {
      _controller?.dispose();
      _controller = null;
      _lastRevealed = null;
      return widget.child;
    }

    final controller = _controller ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: kSectionBuildMs),
    );

    final revealed = ref.watch(sectionRevealedProvider(widget.file));
    _syncToRevealed(revealed, controller);

    return IgnorePointer(
      ignoring: !revealed,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) => Opacity(
          opacity: chromeOpacity(controller.value),
          alwaysIncludeSemantics: true,
          child: SectionBuildScope(progress: controller, child: child!),
        ),
        child: widget.child,
      ),
    );
  }
}
