import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Placeholder landing scaffold.
///
/// The full "agents build the page" experience (build-scenario state machine,
/// pubspec/changelog sections, hot-reload effect, i18n, lite mode) is delivered
/// feature-by-feature through the orchestration pipeline. This is the clean
/// foundation it slots into.
class LandingPage extends StatelessWidget {
  /// Creates the landing scaffold.
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Text(
                r'$ agents build abigotado.dev --release',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: AppColors.textHint,
                ),
              ),
              Text(
                'Nikita Kovalenko',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
