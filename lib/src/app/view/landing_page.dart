import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/app/widget/content_width.dart';
import 'package:abigotado_dev/src/features/changelog/widget/changelog_section.dart';
import 'package:abigotado_dev/src/features/cta/widget/merge_cta_section.dart';
import 'package:abigotado_dev/src/features/hero/view/terminal_hero.dart';
import 'package:abigotado_dev/src/features/metrics/widget/metrics_section.dart';
import 'package:abigotado_dev/src/features/pubspec/widget/pubspec_section.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// The landing scaffold.
///
/// The "agents build the page" hero ([TerminalHero]) opens the page; the
/// name/subtitle, the [MetricsSection], the [PubspecSection], the
/// [ChangelogSection], the [MergeCtaSection], and the locale / effects
/// switchers sit below it. Further sections (hot-reload effect) slot in
/// beneath as they are delivered through the orchestration pipeline.
class LandingPage extends StatelessWidget {
  /// Creates the landing scaffold.
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 24,
      children: [
        const TerminalHero(),
        ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const MetricsSection(),
        const PubspecSection(),
        const ChangelogSection(),
        const MergeCtaSection(),
      ],
    );
  }
}
