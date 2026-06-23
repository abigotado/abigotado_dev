import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/features/hero/state/build_phase.dart';
import 'package:flutter/widgets.dart' show Color;

/// Maps a [BuildPhase] to the build tag's appearance. Single source of truth
/// for DebugReleaseBanner (ribbon) and ReleaseTag (status bar).
/// released → RELEASE/green; planning/coding/reviewing → DEBUG/red+amber.
({String label, Color background, Color foreground}) buildTagStyle(
  BuildPhase phase,
) => switch (phase) {
  BuildPhase.released => (
    label: 'RELEASE',
    background: AppColors.accentGreen,
    foreground: AppColors.background,
  ),
  BuildPhase.planning || BuildPhase.coding || BuildPhase.reviewing => (
    label: 'DEBUG',
    background: AppColors.accentRed,
    foreground: AppColors.accentAmber,
  ),
};
