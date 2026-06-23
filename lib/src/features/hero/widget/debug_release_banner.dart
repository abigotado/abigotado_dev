import 'package:abigotado_dev/src/features/hero/state/build_phase.dart';
import 'package:abigotado_dev/src/features/hero/widget/build_tag_style.dart';
import 'package:abigotado_dev/src/features/hero/widget/build_tag_transition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Flutter debug-banner motif as a corner ribbon: it reads `DEBUG` (amber
/// on red) while the build is in progress and crossfades to `RELEASE` (green
/// on dark) once the scenario reaches [BuildPhase.released].
///
/// Full mode: the ribbon crossfades over 250 ms via [BuildTagTransition], which
/// drives the color lerp and label hard-swap at the midpoint.
/// Lite / reduced-motion: the flip is instant — no ticker, no animation.
///
/// `DEBUG` / `RELEASE` are brand / CLI-style literals (the Flutter banner text
/// and a build mode name) — intentionally NOT localized, like a code keyword.
///
/// Wraps [child] (the terminal) and paints the ribbon over its top-end corner.
class DebugReleaseBanner extends ConsumerWidget {
  /// Creates the debug/release ribbon around [child].
  const DebugReleaseBanner({required this.child, super.key});

  /// The content the ribbon is painted over (the terminal frame).
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BuildTagTransition(
      builder: (context, t) {
        final debug = buildTagStyle(BuildPhase.planning);
        final release = buildTagStyle(BuildPhase.released);
        final background = Color.lerp(debug.background, release.background, t)!;
        final foreground = Color.lerp(debug.foreground, release.foreground, t)!;
        final label = t < 0.5 ? debug.label : release.label;
        return Banner(
          message: label,
          location: BannerLocation.topEnd,
          color: background,
          textStyle: TextStyle(
            color: foreground,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          child: child,
        );
      },
    );
  }
}
