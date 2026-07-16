import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/app/widget/reveal/section_build_scope.dart';
import 'package:abigotado_dev/src/app/widget/reveal/section_build_timing.dart';
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
/// Delegates to [_AnimatedHeading] — see its doc for the render. Reachable
/// once a `RevealBuild` ancestor is in full mode and mid-build.
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
/// ## Render
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
/// heading must not visibly grow/shrink while typing. [_BuildCursorGlyph]
/// measures [style]'s own line height rather than assuming a font-metric
/// ratio, so this holds for whatever [TextStyle] a caller passes.
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
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final length = text.length;
        final shown = headingCharsShown(progress.value, length);
        return Semantics(
          label: text,
          child: ExcludeSemantics(
            child: Text.rich(
              TextSpan(
                style: style,
                children: [
                  TextSpan(text: text.substring(0, shown)),
                  if (headingCursorVisible(progress.value))
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: _BuildCursorGlyph(style: style),
                    ),
                ],
              ),
              overflow: overflow,
            ),
          ),
        );
      },
    );
  }
}

/// The solid block caret shown by [_AnimatedHeading] while typing.
///
/// Sized from [style]'s *own* measured line height (via a throwaway
/// [TextPainter] rather than an assumed font-metric ratio) so it fits inside
/// the paragraph's line box under any [TextStyle] a caller passes —
/// embedding it as a [WidgetSpan] must never grow the heading's height.
class _BuildCursorGlyph extends StatelessWidget {
  const _BuildCursorGlyph({required this.style});

  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final metrics = TextPainter(
      text: TextSpan(text: 'M', style: style),
      textDirection: Directionality.of(context),
    )..layout();
    final fontSize = style.fontSize ?? metrics.height;
    return Container(
      width: fontSize * 0.6,
      // A margin under the measured line height: the placeholder must never
      // be the tallest thing on the line, whatever style is passed in.
      height: metrics.height * 0.85,
      color: AppColors.accentTeal,
    );
  }
}
