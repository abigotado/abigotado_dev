import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Pure content guard tests — no widgets, no BuildContext, no mocks (except
// where localization loading is needed).
//
// Locks the owner's repositioning decision: `sub` and `pubspec_description`
// lead with "lead" (team lead / tech lead), not "senior" — see
// landing-positioning memory. These PASS from birth against the real arb
// content. Passes on stub — must STAY green.
// ---------------------------------------------------------------------------

void main() {
  final locales = [
    const Locale('en'),
    const Locale('ru'),
    const Locale('es'),
  ];

  group('sub', () {
    for (final locale in locales) {
      testWidgets(
        'does not start with "senior" — locale ${locale.languageCode}',
        (tester) async {
          final l10n = await AppLocalizations.delegate.load(locale);

          expect(
            l10n.sub.trim().toLowerCase().startsWith('senior'),
            isFalse,
            reason:
                '"${l10n.sub}" (${locale.languageCode}) must not lead with '
                '"senior" — the landing leads with lead-first positioning',
          );
        },
      );
    }
  });

  group('pubspec_description', () {
    for (final locale in locales) {
      testWidgets(
        'does not start with "senior" — locale ${locale.languageCode}',
        (tester) async {
          final l10n = await AppLocalizations.delegate.load(locale);

          expect(
            l10n.pubspec_description.trim().toLowerCase().startsWith(
              'senior',
            ),
            isFalse,
            reason:
                '"${l10n.pubspec_description}" (${locale.languageCode}) '
                'must not lead with "senior"',
          );
        },
      );
    }
  });
}
