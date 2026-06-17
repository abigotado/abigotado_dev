import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/features/cta/content/cta_content.dart';
import 'package:abigotado_dev/src/features/cta/widget/contact_link_tile.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// The revealed contacts panel shown after the merge button is tapped.
///
/// Renders the `cta_heading` localized heading and a [Wrap] of
/// [ContactLinkTile] widgets built from [contactLinks]. Wraps cleanly at 320 px
/// (the narrowest mobile viewport we target).
class ContactsPanel extends StatelessWidget {
  /// Creates the contacts panel.
  const ContactsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        Text(
          l10n.cta_heading,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final link in contactLinks) ContactLinkTile(link: link),
          ],
        ),
      ],
    );
  }
}
