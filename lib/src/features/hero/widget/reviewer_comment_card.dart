import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/features/hero/state/build_phase.dart';
import 'package:abigotado_dev/src/features/hero/state/build_scenario_notifier.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The reviewer's comment card — the "reviewer nitpicks, then approves" beat.
///
/// Watches the scenario's [ReviewStatus]: while [ReviewStatus.nitpicking] it
/// shows the change-request comment in a red-accented card; once
/// [ReviewStatus.approved] it shows the approval in a green/teal card.
///
/// The `reviewer` header label is a code-identity literal (not localized, like
/// an agent identifier); the header line and body text come from arb.
class ReviewerCommentCard extends ConsumerWidget {
  /// Creates the reviewer comment card.
  const ReviewerCommentCard({super.key});

  /// The reviewer's identifier — a literal, not an arb key (see class doc).
  static const String _reviewer = 'reviewer';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final review = ref.watch(
      buildScenarioProvider.select((state) => state.review),
    );
    final approved = review == ReviewStatus.approved;

    final accent = approved ? AppColors.accentGreen : AppColors.accentRed;
    final body = approved ? l10n.revtext_done : l10n.revtext_run;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(left: BorderSide(color: accent, width: 3)),
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Text(
                _reviewer,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: approved ? AppColors.accentTeal : accent,
                ),
              ),
              Expanded(
                child: Text(
                  l10n.rev_hdr,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          Text(
            body,
            softWrap: true,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
