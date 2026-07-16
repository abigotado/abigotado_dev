import 'package:abigotado_dev/src/app/widget/editor_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps [child] in the "section build" reveal — the effect that replaces
/// `RevealOnScroll`'s plain fade+slide for the metrics/pubspec/changelog/
/// contacts sections: instead of just appearing, the section renders as if
/// the agent pipeline is assembling it live (chrome fades in, the heading
/// types itself out, then its content cascades in), mirroring the hero's
/// planner → coder → reviewer conceit at the section level.
///
/// ## Intended GREEN render
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
/// `build` is an identity passthrough: `child` renders unchanged, in every
/// mode, with no controller and no `SectionBuildScope` provided (so every
/// `TypeOnHeading`/`BuildCascadeItem` beneath it stays on its static
/// branch). This is required — not just permitted — during the contracts
/// pass: `LandingPage` already wires this widget in for the metrics/
/// pubspec/changelog/contacts sections, so its render must be indistinguishable
/// from the `RevealOnScroll` it replaces until the red suite (against the
/// "Intended GREEN render" above) drives the real implementation.
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

class _RevealBuildState extends ConsumerState<RevealBuild> {
  @override
  Widget build(BuildContext context) {
    // CONTRACTS pass — see the class doc's "THIS PASS" note.
    return widget.child;
  }
}
