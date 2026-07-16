import 'package:flutter/widgets.dart';

/// Publishes the in-progress section-build [progress] animation to
/// descendants — the leaf primitives (`TypeOnHeading`, `BuildCascadeItem`)
/// that render differently while a section is still "being built" — without
/// making them rebuild on every animation tick.
///
/// ### Why a no-dependency lookup
///
/// [maybeOf] resolves via [BuildContext.getInheritedWidgetOfExactType],
/// **not** `dependOnInheritedWidgetOfExactType`. The latter would register a
/// build dependency on [SectionBuildScope] itself, so every descendant that
/// calls it would rebuild on every animation frame — for an 800 ms build at
/// 60 fps, that is the whole card subtree rebuilding roughly 48 times for a
/// single reveal. Instead, each descendant reads [progress] once (to decide
/// whether it is in "building" or "static" mode) and, if building, wraps
/// itself in its own `AnimatedBuilder` listening directly to that
/// `Animation<double>` — so only the small painted region that actually
/// changes (a cursor glyph, an item's opacity/offset) re-paints per tick, not
/// the whole card.
///
/// ### Identity invariant
///
/// The providing `RevealBuild` creates its `AnimationController` exactly
/// once (lazily, on the first full-mode build) and never swaps the instance
/// for the lifetime of that state — only the controller's *value* changes.
/// [updateShouldNotify] compares [progress] by identity (`!=`), which is why
/// this is safe: in practice the same controller instance is passed on every
/// rebuild, so [updateShouldNotify] is always `false` and — combined with the
/// no-dependency lookup above — [SectionBuildScope] itself never triggers a
/// dependent rebuild in this app.
class SectionBuildScope extends InheritedWidget {
  /// Wraps [child] in a scope publishing [progress] for the leaf build
  /// primitives beneath it to discover via [maybeOf].
  const SectionBuildScope({
    required this.progress,
    required super.child,
    super.key,
  });

  /// The normalized `[0, 1]` build-progress animation driving every
  /// build-in-progress affordance beneath this scope.
  final Animation<double> progress;

  /// Returns the nearest enclosing [SectionBuildScope]'s [progress], or
  /// `null` when [context] is not beneath one — e.g. lite mode (`RevealBuild`
  /// never provides a scope there) or any tree outside a `RevealBuild`
  /// altogether. Callers treat `null` as their static-render branch.
  ///
  /// A *completed* build does **not** become `null`: the scope and its
  /// `Animation<double>` persist for the section's lifetime, simply parked at
  /// value `1.0` once the controller finishes — callers read that value like
  /// any other progress and are expected to converge to a static-identical
  /// render at `1.0`, not to special-case completion by tearing anything
  /// down.
  ///
  /// Deliberately does **not** establish a build dependency — see the class
  /// doc for why.
  static Animation<double>? maybeOf(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<SectionBuildScope>();
    return scope?.progress;
  }

  @override
  bool updateShouldNotify(SectionBuildScope oldWidget) =>
      progress != oldWidget.progress;
}
