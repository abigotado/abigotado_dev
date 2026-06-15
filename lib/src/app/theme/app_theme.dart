import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Builds the application's dark [ThemeData].
///
/// Kept as a pure function of [AppColors] so the palette stays the single
/// source of truth and the theme has no hidden constants.
abstract final class AppTheme {
  /// The site's only theme — a dark, terminal-flavored surface.
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      surface: AppColors.background,
      primary: AppColors.accentTeal,
      secondary: AppColors.accentPurple,
      error: AppColors.accentRed,
      onSurface: AppColors.textPrimary,
    );

    final base = ThemeData.from(colorScheme: scheme, useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
    );
  }
}
