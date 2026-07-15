import 'package:abigotado_dev/src/features/readme/content/experience_content.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Pure content guard tests — no widgets, no BuildContext, no mocks (except
// where localization loading is needed).
//
// These PASS from birth (mirrors changelog_content_test.dart) — they guard
// the owner's hard rules against the real experienceEntries list. A future
// content edit that violates a rule will break one of these tests.
// Passes on stub — must STAY green.
// ---------------------------------------------------------------------------

void main() {
  group('experienceEntries', () {
    group('count', () {
      test('exactly 6 entries', () {
        expect(experienceEntries.length, equals(6));
      });
    });

    group('achievements count', () {
      test('every entry has 3 to 4 achievements', () {
        for (final entry in experienceEntries) {
          expect(
            entry.achievements.length,
            inInclusiveRange(3, 4),
            reason:
                'entry with ${entry.achievements.length} achievements '
                'violates the 3–4 bullet contract',
          );
        }
      });
    });

    group('url', () {
      test('every entry.url is null (stage-1 pin; stage 3 relaxes)', () {
        for (final entry in experienceEntries) {
          expect(
            entry.url,
            isNull,
            reason:
                'stage 1: every org must render as plain text — url is '
                'null until stage 3 fills in a real link target',
          );
        }
      });
    });

    // -----------------------------------------------------------------------
    // Org resolves PER-LOCALE — locks org-as-LocalizedText against a future
    // "simplification" to a plain String. Uses the delegate.load pattern from
    // changelog_content_test.dart.
    // -----------------------------------------------------------------------
    group('org resolves per-locale', () {
      testWidgets(
        'РЖД (index 4): ru org == РЖД, en org == Russian Railways',
        (tester) async {
          final ru = await AppLocalizations.delegate.load(const Locale('ru'));
          final en = await AppLocalizations.delegate.load(const Locale('en'));

          final entry = experienceEntries[4];

          expect(entry.org(ru), equals('РЖД'));
          expect(entry.org(en), equals('Russian Railways'));
        },
      );

      testWidgets(
        'entry 2 (index 2): ru org differs from en org — '
        'Цифровые технологии и платформы vs Digital Technologies & Platforms',
        (tester) async {
          final ru = await AppLocalizations.delegate.load(const Locale('ru'));
          final en = await AppLocalizations.delegate.load(const Locale('en'));

          final entry = experienceEntries[2];

          expect(entry.org(ru), equals('Цифровые технологии и платформы'));
          expect(entry.org(en), equals('Digital Technologies & Platforms'));
          expect(
            entry.org(ru),
            isNot(equals(entry.org(en))),
            reason:
                'org must resolve per-locale — a String simplification '
                'would collapse this to one invariant value',
          );
        },
      );
    });

    // -----------------------------------------------------------------------
    // No-dates guard — requires localization to inspect prose.
    // -----------------------------------------------------------------------
    group('no calendar dates', () {
      final locales = [
        const Locale('en'),
        const Locale('ru'),
        const Locale('es'),
      ];
      final yearPattern = RegExp(r'\b(19|20)\d{2}\b');

      for (final locale in locales) {
        testWidgets(
          'no 4-digit year in org/role/summary/achievements — locale '
          '${locale.languageCode}',
          (tester) async {
            final l10n = await AppLocalizations.delegate.load(locale);

            for (final entry in experienceEntries) {
              final org = entry.org(l10n);
              final role = entry.role(l10n);
              final summary = entry.summary(l10n);

              expect(
                org,
                isNot(matches(yearPattern)),
                reason:
                    'no employment dates: org "$org" '
                    '(${locale.languageCode}) contains a 4-digit year',
              );
              expect(
                role,
                isNot(matches(yearPattern)),
                reason:
                    'no employment dates: role "$role" '
                    '(${locale.languageCode}) contains a 4-digit year',
              );
              expect(
                summary,
                isNot(matches(yearPattern)),
                reason:
                    'no employment dates: summary "$summary" '
                    '(${locale.languageCode}) contains a 4-digit year',
              );

              for (final achievement in entry.achievements) {
                final text = achievement(l10n);
                expect(
                  text,
                  isNot(matches(yearPattern)),
                  reason:
                      'no employment dates: achievement "$text" '
                      '(${locale.languageCode}) contains a 4-digit year',
                );
              }
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
          'no "python" in org/role/summary/achievements — locale '
          '${locale.languageCode}',
          (tester) async {
            final l10n = await AppLocalizations.delegate.load(locale);

            for (final entry in experienceEntries) {
              final org = entry.org(l10n).toLowerCase();
              final role = entry.role(l10n).toLowerCase();
              final summary = entry.summary(l10n).toLowerCase();

              expect(
                org,
                isNot(contains('python')),
                reason:
                    'org "${entry.org(l10n)}" (${locale.languageCode}) '
                    'must not mention Python',
              );
              expect(
                role,
                isNot(contains('python')),
                reason:
                    'role "${entry.role(l10n)}" (${locale.languageCode}) '
                    'must not mention Python',
              );
              expect(
                summary,
                isNot(contains('python')),
                reason:
                    'summary "${entry.summary(l10n)}" '
                    '(${locale.languageCode}) must not mention Python',
              );

              for (final achievement in entry.achievements) {
                final text = achievement(l10n).toLowerCase();
                expect(
                  text,
                  isNot(contains('python')),
                  reason:
                      'achievement "${achievement(l10n)}" '
                      '(${locale.languageCode}) must not mention Python',
                );
              }
            }
          },
        );
      }
    });
  });
}
