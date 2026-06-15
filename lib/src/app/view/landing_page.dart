import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/features/locale/widget/locale_switcher.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// Placeholder landing scaffold.
///
/// The full "agents build the page" experience (build-scenario state machine,
/// pubspec/changelog sections, hot-reload effect, lite mode) is delivered
/// feature-by-feature through the orchestration pipeline. This is the clean
/// foundation it slots into.
class LandingPage extends StatelessWidget {
  /// Creates the landing scaffold.
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 24,
            children: [
              Column(
                spacing: 8,
                children: [
                  Text(
                    l10n.name,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    l10n.sub,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              Column(
                spacing: 8,
                children: [
                  const LocaleSwitcher(),
                  Text(
                    l10n.langhint,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
