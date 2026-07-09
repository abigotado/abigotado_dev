import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/app/widget/content_width.dart';
import 'package:abigotado_dev/src/features/readme/view/readme_navigation.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The first-child chip that opens the `README.md` document.
///
/// Sits outside every landing-page `KeyedSubtree` (see `LandingPage`), above
/// the hero section, so it never shifts any section's measured scroll-spy
/// offset.
///
/// `openReadme` is the navigation helper in `readme_navigation.dart`. Tap
/// target ≥ 44 px (WCAG 2.5.5), same idiom as `ContactLinkTile` /
/// `EditorFileRow`.
class ReadmeEntryChip extends ConsumerWidget {
  /// Creates the README entry chip.
  const ReadmeEntryChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return ContentWidth(
      child: Semantics(
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => openReadme(context, ref),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              spacing: 8,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.description_outlined,
                  size: 16,
                  color: AppColors.accentTeal,
                ),
                Text(
                  l10n.rm_entry_chip,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: AppColors.accentTeal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
