import 'package:abigotado_dev/src/features/readme/content/education_content.dart';
import 'package:abigotado_dev/src/features/readme/content/readme_skills_content.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Pure content guard tests — no widgets, no BuildContext, no mocks (except
// where localization loading is needed).
//
// These PASS from birth — they guard the owner's hard rules against the real
// readmeSkillGroups / educationEntries / certifications lists and rm_languages.
// Passes on stub — must STAY green.
// ---------------------------------------------------------------------------

void main() {
  final locales = [
    const Locale('en'),
    const Locale('ru'),
    const Locale('es'),
  ];

  group('readmeSkillGroups', () {
    group('count', () {
      test('exactly 5 skill groups', () {
        expect(readmeSkillGroups.length, equals(5));
      });
    });

    group('non-empty title and body', () {
      for (final locale in locales) {
        testWidgets(
          'every group has a non-empty title and body — locale '
          '${locale.languageCode}',
          (tester) async {
            final l10n = await AppLocalizations.delegate.load(locale);

            for (final group in readmeSkillGroups) {
              expect(
                group.title(l10n),
                isNotEmpty,
                reason:
                    'skill group title must not be empty '
                    '(${locale.languageCode})',
              );
              expect(
                group.body(l10n),
                isNotEmpty,
                reason:
                    'skill group body must not be empty '
                    '(${locale.languageCode})',
              );
            }
          },
        );
      }
    });
  });

  group('educationEntries', () {
    group('count', () {
      test('exactly 2 entries', () {
        expect(educationEntries.length, equals(2));
      });
    });

    group('non-empty title and detail', () {
      for (final locale in locales) {
        testWidgets(
          'every entry has a non-empty title and detail — locale '
          '${locale.languageCode}',
          (tester) async {
            final l10n = await AppLocalizations.delegate.load(locale);

            for (final entry in educationEntries) {
              expect(entry.title(l10n), isNotEmpty);
              expect(entry.detail(l10n), isNotEmpty);
            }
          },
        );
      }
    });
  });

  group('certifications', () {
    group('count', () {
      test('exactly 2 entries', () {
        expect(certifications.length, equals(2));
      });
    });

    group('non-empty', () {
      for (final locale in locales) {
        testWidgets(
          'every certification line is non-empty — locale '
          '${locale.languageCode}',
          (tester) async {
            final l10n = await AppLocalizations.delegate.load(locale);

            for (final cert in certifications) {
              expect(cert(l10n), isNotEmpty);
            }
          },
        );
      }
    });
  });

  group('rm_languages', () {
    for (final locale in locales) {
      testWidgets(
        'non-empty and contains C2 — locale ${locale.languageCode}',
        (tester) async {
          final l10n = await AppLocalizations.delegate.load(locale);

          expect(l10n.rm_languages, isNotEmpty);
          expect(
            l10n.rm_languages,
            contains('C2'),
            reason:
                'rm_languages must state the C2 proficiency level '
                '(${locale.languageCode})',
          );
        },
      );
    }
  });
}
