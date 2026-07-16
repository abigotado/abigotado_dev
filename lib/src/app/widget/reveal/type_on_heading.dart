import 'package:abigotado_dev/src/app/widget/reveal/section_build_scope.dart';
import 'package:flutter/widgets.dart';

/// Renders [text] as a heading that either sits static or types itself out
/// with a blinking cursor, depending on whether it is beneath an
/// in-progress `RevealBuild` — discovered via [SectionBuildScope.maybeOf],
/// never watched/passed explicitly, so ordinary callers (e.g. `SectionCard`)
/// need no awareness of the build effect at all.
///
/// ## Static branch (`SectionBuildScope.maybeOf` returns `null`)
///
/// A bare [Text] — no `Semantics`/`ExcludeSemantics` wrapper. This is load
/// bearing: `SectionCard` (this widget's current caller) is pinned
/// a11y-neutral by `section_card_test.dart`, and the section goldens pin
/// these exact pixels. `null` covers lite mode, a finished-but-torn-down
/// build (does not currently happen — see `SectionBuildScope`'s doc), and
/// simply not being under a `RevealBuild` at all.
///
/// ## Animated branch (`SectionBuildScope.maybeOf` returns non-`null`)
///
/// Delegates to [_AnimatedHeading] — see its doc for the intended green-pass
/// render. Unreachable in the CONTRACTS pass: `RevealBuild`'s current stub
/// never provides a [SectionBuildScope], so [build] always takes the static
/// branch today.
class TypeOnHeading extends StatelessWidget {
  /// Creates a self-typing heading for [text].
  const TypeOnHeading({
    required this.text,
    required this.style,
    this.overflow,
    super.key,
  });

  /// The full heading text — shown in both the static and animated render,
  /// and always the complete string exposed to assistive tech (screen
  /// readers never wait for the type-out).
  final String text;

  /// The text style, applied identically by both branches.
  final TextStyle style;

  /// Overflow handling, forwarded to the static [Text] and (green pass) to
  /// the animated branch's own text.
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final progress = SectionBuildScope.maybeOf(context);
    if (progress == null) {
      return Text(text, style: style, overflow: overflow);
    }
    return _AnimatedHeading(
      text: text,
      style: style,
      overflow: overflow,
      progress: progress,
    );
  }
}

/// The typing-cursor render of [TypeOnHeading], active while its section's
/// build is in progress.
///
/// ## Intended GREEN render
///
/// ```dart
/// return AnimatedBuilder(
///   animation: progress,
///   builder: (context, _) {
///     final length = text.length;
///     final shown = headingCharsShown(progress.value, length);
///     return Semantics(
///       label: text,
///       child: ExcludeSemantics(
///         child: Text.rich(
///           TextSpan(
///             style: style,
///             children: [
///               TextSpan(text: text.substring(0, shown)),
///               if (headingCursorVisible(progress.value))
///                 WidgetSpan(
///                   alignment: PlaceholderAlignment.middle,
///                   child: BuildCursorGlyph(style: style),
///                 ),
///             ],
///           ),
///           overflow: overflow,
///         ),
///       ),
///     );
///   },
/// );
/// ```
///
/// `Semantics(label: text)` always carries the *complete* string — an
/// assistive-tech user gets the full heading from frame 1, regardless of how
/// much has visually "typed" — while `ExcludeSemantics` hides the decorative
/// partial-text-plus-cursor visual from the semantics tree so it is not
/// announced underneath the label.
///
/// **Cursor sizing constraint (advisor-pinned):** the cursor glyph's own
/// height must stay within [style]'s line-box height at every frame — the
/// heading must not visibly grow/shrink while typing. A green-pass test
/// samples a mid-progress frame and asserts the heading's laid-out height is
/// unchanged from its settled (fully-typed) height.
///
/// Unreachable in the CONTRACTS pass: [TypeOnHeading.build] only constructs
/// this widget when [SectionBuildScope.maybeOf] is non-`null`, and
/// `RevealBuild`'s current stub never provides one.
class _AnimatedHeading extends StatelessWidget {
  const _AnimatedHeading({
    required this.text,
    required this.style,
    required this.overflow,
    required this.progress,
  });

  final String text;
  final TextStyle style;
  final TextOverflow? overflow;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) => throw UnimplementedError('green pass');
}
