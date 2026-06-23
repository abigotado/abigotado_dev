import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/app/widget/content_width.dart';
import 'package:abigotado_dev/src/app/widget/editor_file.dart';
import 'package:abigotado_dev/src/app/widget/reveal_on_scroll.dart';
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
///
/// [sectionKeys] maps each [EditorFile] to the [GlobalKey] for its section
/// widget. The scroll host owns these keys and passes them in so the
/// scroll-spy logic can measure section positions in scroll-content
/// coordinates.
class LandingPage extends StatelessWidget {
  /// Creates the landing scaffold.
  ///
  /// [sectionKeys] must contain a key for every [EditorFile] value; the scroll
  /// host always provides a complete map.
  const LandingPage({required this.sectionKeys, super.key});

  /// One [GlobalKey] per [EditorFile], placed on the corresponding section.
  final Map<EditorFile, GlobalKey> sectionKeys;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 24,
      children: [
        // Hero section: terminal widget + name/subtitle block share one key so
        // the scroll-spy can treat the combined hero as a single section.
        // KeyedSubtree is outermost; RevealOnScroll wraps the content inside.
        KeyedSubtree(
          key: sectionKeys[EditorFile.fileHero],
          child: RevealOnScroll(
            file: EditorFile.fileHero,
            child: Column(
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
              ],
            ),
          ),
        ),
        KeyedSubtree(
          key: sectionKeys[EditorFile.metrics],
          child: const RevealOnScroll(
            file: EditorFile.metrics,
            child: MetricsSection(),
          ),
        ),
        KeyedSubtree(
          key: sectionKeys[EditorFile.pubspec],
          child: const RevealOnScroll(
            file: EditorFile.pubspec,
            child: PubspecSection(),
          ),
        ),
        KeyedSubtree(
          key: sectionKeys[EditorFile.changelog],
          child: const RevealOnScroll(
            file: EditorFile.changelog,
            child: ChangelogSection(),
          ),
        ),
        KeyedSubtree(
          key: sectionKeys[EditorFile.contacts],
          child: const RevealOnScroll(
            file: EditorFile.contacts,
            child: MergeCtaSection(),
          ),
        ),
      ],
    );
  }
}
