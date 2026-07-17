import 'package:abigotado_dev/src/app/widget/reveal/section_build_scope.dart';
import 'package:abigotado_dev/src/app/widget/reveal/section_build_timing.dart';
import 'package:flutter/widgets.dart';

/// Wraps one item of a section's content — a `_LogEntry`, a metric card, the
/// pubspec code body — so it fades and slides in during its `RevealBuild`
/// cascade phase, staggered by [index] of [count] total items.
///
/// Like `TypeOnHeading`, the animated behavior is entirely opt-in via
/// [SectionBuildScope.maybeOf]: a caller outside any `RevealBuild` (or under
/// one in lite mode, or in this CONTRACTS pass where `RevealBuild` never
/// provides a scope) gets [child] back completely unchanged.
///
/// ## Static branch (`SectionBuildScope.maybeOf` returns `null`)
///
/// Returns [child] verbatim — no `Opacity`, no `FractionalTranslation`, not
/// even an extra layout box. This keeps the wrapped content's layout/paint
/// output byte-identical to not being wrapped at all, which is exactly what
/// lets the section goldens stay pinned through this pass.
///
/// ## Animated branch (`SectionBuildScope.maybeOf` returns non-`null`)
///
/// Delegates to [_AnimatedCascadeItem] — see its doc for the render.
class BuildCascadeItem extends StatelessWidget {
  /// Creates a cascade-staggered wrapper for item [index] of [count].
  const BuildCascadeItem({
    required this.index,
    required this.count,
    required this.child,
    super.key,
  });

  /// This item's 0-based position in the cascade, passed straight through
  /// to `cascadeItemInterval`/`cascadeItemOpacity`/`cascadeItemSlideDy`.
  final int index;

  /// The total number of items in this cascade (the caller's list length).
  final int count;

  /// The item content to reveal.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final progress = SectionBuildScope.maybeOf(context);
    if (progress == null) return child;
    return _AnimatedCascadeItem(
      index: index,
      count: count,
      progress: progress,
      child: child,
    );
  }
}

/// The fade/slide render of [BuildCascadeItem], active while its section's
/// build is in progress.
///
/// ## Render
///
/// ```dart
/// return AnimatedBuilder(
///   animation: progress,
///   // `child` here is the AnimatedBuilder-cached widget subtree (this
///   // class's own `child` field, passed via the `child:` argument below) —
///   // it is built once, not reconstructed on every tick; only the Opacity/
///   // FractionalTranslation wrapper repaints per frame.
///   builder: (context, child) => Opacity(
///     opacity: cascadeItemOpacity(progress.value, index, count),
///     // The item is genuinely present (mid-cascade content is still
///     // meaningful, unlike a decorative overlay), so its semantics must
///     // stay reachable at every opacity — mirrors `reveal_on_scroll.dart`'s
///     // `alwaysIncludeSemantics: true` on its own AnimatedOpacity.
///     alwaysIncludeSemantics: true,
///     child: FractionalTranslation(
///       translation: Offset(
///         0,
///         cascadeItemSlideDy(progress.value, index, count),
///       ),
///       child: child,
///     ),
///   ),
///   child: child, // this widget's own `child` field.
/// );
/// ```
///
/// Paint-only: `Opacity` and `FractionalTranslation` both apply during
/// painting, never affecting layout or size — a cascading item must never
/// shift its siblings or change the section's overall height as it
/// animates in.
class _AnimatedCascadeItem extends StatelessWidget {
  const _AnimatedCascadeItem({
    required this.index,
    required this.count,
    required this.progress,
    required this.child,
  });

  final int index;
  final int count;
  final Animation<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      // `child` here is the AnimatedBuilder-cached widget subtree (this
      // class's own `child` field, passed via the `child:` argument below) —
      // it is built once, not reconstructed on every tick; only the Opacity/
      // FractionalTranslation wrapper repaints per frame.
      builder: (context, child) => Opacity(
        opacity: cascadeItemOpacity(progress.value, index, count),
        // The item is genuinely present (mid-cascade content is still
        // meaningful, unlike a decorative overlay), so its semantics must
        // stay reachable at every opacity — mirrors `reveal_on_scroll.dart`'s
        // `alwaysIncludeSemantics: true` on its own AnimatedOpacity.
        alwaysIncludeSemantics: true,
        child: FractionalTranslation(
          translation: Offset(
            0,
            cascadeItemSlideDy(progress.value, index, count),
          ),
          child: child,
        ),
      ),
      child: child, // this widget's own `child` field.
    );
  }
}
