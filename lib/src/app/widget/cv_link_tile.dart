import 'package:abigotado_dev/src/app/widget/contact_link_tile.dart';
import 'package:abigotado_dev/src/core/content/contact_link.dart';
import 'package:abigotado_dev/src/core/content/cv_document.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// A contact chip that opens the résumé PDF in the active locale's language.
///
/// Sits next to the [ContactLinkTile]s built from `contactLinks`, but is not
/// one of their entries: both its label and its target depend on the locale.
class CvLinkTile extends StatelessWidget {
  /// Creates the résumé PDF chip.
  const CvLinkTile({super.key});

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

    return ContactLinkTile(
      link: ContactLink(
        label: AppLocalizations.of(context).cv_pdf,
        url: cvPdfUrl(languageCode),
      ),
    );
  }
}
