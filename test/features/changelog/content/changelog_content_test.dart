import 'package:abigotado_dev/src/features/changelog/content/changelog_content.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Pure content guard tests — no widgets, no BuildContext, no mocks (except
// where localization loading is needed).
//
// These PASS from birth — they guard the owner's hard rules against the
// real careerEntries list. A future content edit that violates a rule will
// break one of these tests.
// ---------------------------------------------------------------------------

void main() {
  group('careerEntries', () {
    // -----------------------------------------------------------------------
    // Structural integrity
    // -----------------------------------------------------------------------
    group('count', () {
      test('exactly 5 entries', () {
        expect(careerEntries.length, equals(5));
      });
    });

    group('version format', () {
      test('every version is a semver tag starting with v + digit', () {
        final semverPrefix = RegExp(r'^v\d');
        for (final entry in careerEntries) {
          expect(
            entry.version,
            matches(semverPrefix),
            reason:
                'version "${entry.version}" must match semver convention '
                r'(^v\d) — dates or plain labels are not allowed',
          );
        }
      });
    });

    group('version order', () {
      test('newest-first and all five tags present', () {
        final versions = careerEntries.map((e) => e.version).toList();
        expect(
          versions,
          equals(['v5.x', 'v4.x', 'v3.x', 'v2.x', 'v1.0']),
          reason:
              'versions must be newest-first and unique; '
              'got: $versions',
        );
      });
    });

    // -----------------------------------------------------------------------
    // No-dates guard — requires localization to inspect prose
    // -----------------------------------------------------------------------
    group('no calendar dates', () {
      // A 4-digit year (1900–2099) appearing in career prose would violate
      // the hard "no employment dates" rule. Scans org + what only — NOT
      // version (which is a semver tag and legitimately contains digits).
      final locales = [
        const Locale('en'),
        const Locale('ru'),
        const Locale('es'),
      ];
      final yearPattern = RegExp(r'\b(19|20)\d{2}\b');

      for (final locale in locales) {
        testWidgets(
          'no 4-digit year in org/what prose — locale ${locale.languageCode}',
          (tester) async {
            final l10n = await AppLocalizations.delegate.load(locale);

            for (final entry in careerEntries) {
              final org = entry.org(l10n);
              final what = entry.what(l10n);

              expect(
                org,
                isNot(matches(yearPattern)),
                reason:
                    'no employment dates: org "$org" (${entry.version}, '
                    '${locale.languageCode}) contains a 4-digit year',
              );
              expect(
                what,
                isNot(matches(yearPattern)),
                reason:
                    'no employment dates: what "$what" (${entry.version}, '
                    '${locale.languageCode}) contains a 4-digit year',
              );
            }
          },
        );
      }
    });

    // -----------------------------------------------------------------------
    // No Python
    // -----------------------------------------------------------------------
    group('no Python mentions', () {
      final locales = [
        const Locale('en'),
        const Locale('ru'),
        const Locale('es'),
      ];

      for (final locale in locales) {
        testWidgets(
          'no "python" in org/what — locale ${locale.languageCode}',
          (tester) async {
            final l10n = await AppLocalizations.delegate.load(locale);

            for (final entry in careerEntries) {
              final org = entry.org(l10n).toLowerCase();
              final what = entry.what(l10n).toLowerCase();

              expect(
                org,
                isNot(contains('python')),
                reason:
                    'org "${entry.org(l10n)}" (${entry.version}, '
                    '${locale.languageCode}) must not mention Python',
              );
              expect(
                what,
                isNot(contains('python')),
                reason:
                    'what "${entry.what(l10n)}" (${entry.version}, '
                    '${locale.languageCode}) must not mention Python',
              );
            }
          },
        );
      }
    });
  });
}
