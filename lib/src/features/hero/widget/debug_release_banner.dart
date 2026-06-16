import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/features/hero/state/build_phase.dart';
import 'package:abigotado_dev/src/features/hero/state/build_scenario_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Flutter debug-banner motif as a corner ribbon: it reads `DEBUG` (amber
/// on red) while the build is in progress and flips to `RELEASE` (green) once
/// the scenario reaches [BuildPhase.released].
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
    final released =
        ref.watch(
          buildScenarioProvider.select((state) => state.phase),
        ) ==
        BuildPhase.released;

    // `DEBUG` / `RELEASE` are build-mode literals, not user-facing copy.
    final (label, background, foreground) = switch (released) {
      false => ('DEBUG', AppColors.accentRed, AppColors.accentAmber),
      true => ('RELEASE', AppColors.accentGreen, AppColors.background),
    };

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
  }
}
