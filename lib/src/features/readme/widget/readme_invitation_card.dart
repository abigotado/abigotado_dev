import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/app/widget/content_width.dart';
import 'package:abigotado_dev/src/features/readme/view/readme_navigation.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The closing invitation card that opens the `README.md` document.
///
/// Sits after the contacts `KeyedSubtree` and before `LandingPage`'s FAB
/// clearance `SizedBox`, outside every `KeyedSubtree` — same rationale as
/// `ReadmeEntryChip`: it must never shift a section's measured scroll-spy
/// offset.
///
/// Same `onTap` target as `ReadmeEntryChip` — both funnel through the single
/// `openReadme` helper. Tap target ≥ 44 px (WCAG 2.5.5).
class ReadmeInvitationCard extends ConsumerWidget {
  /// Creates the README invitation card.
  const ReadmeInvitationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return ContentWidth(
      child: Semantics(
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => openReadme(context, ref),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(16),
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.rm_invitation,
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
              softWrap: true,
            ),
          ),
        ),
      ),
    );
  }
}
