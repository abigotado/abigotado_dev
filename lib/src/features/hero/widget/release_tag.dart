import 'package:abigotado_dev/src/features/hero/state/build_phase.dart';
import 'package:abigotado_dev/src/features/hero/widget/build_tag_style.dart';
import 'package:abigotado_dev/src/features/hero/widget/build_tag_transition.dart';
import 'package:flutter/widgets.dart';

/// A small pill badge that shows `DEBUG` (red-on-red-wash) while the build is
/// in progress and crossfades to `RELEASE` (green-on-green-wash) once the
/// scenario reaches [BuildPhase.released].
///
/// Full mode: a 250 ms crossfade driven by [BuildTagTransition]. The accent
/// color lerps from accentRed to accentGreen and the label hard-swaps at
/// the midpoint.
///
/// Lite / reduced-motion: the label and color flip instantly with no ticker.
///
/// Color treatment: the pill uses `buildTagStyle(phase).background` as its
/// ACCENT (text color = accent, pill background = accent at alpha 0.15). The
/// `.foreground` field is the banner's text-on-solid color and is NOT used
/// here.
class ReleaseTag extends StatelessWidget {
  /// Creates the release tag badge.
  const ReleaseTag({super.key});

  @override
  Widget build(BuildContext context) {
    return BuildTagTransition(
      builder: (context, t) {
        final debug = buildTagStyle(BuildPhase.planning);
        final release = buildTagStyle(BuildPhase.released);
        // `buildTagStyle` is the single source of truth for both label and
        // accent; the pill uses `.background` as its accent (text + wash).
        final accent = Color.lerp(debug.background, release.background, t)!;
        final label = t < 0.5 ? debug.label : release.label;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        );
      },
    );
  }
}
