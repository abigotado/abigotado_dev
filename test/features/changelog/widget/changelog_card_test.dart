import 'package:abigotado_dev/src/app/theme/app_theme.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/core/effects/effects_store.dart';
import 'package:abigotado_dev/src/features/changelog/widget/changelog_card.dart';
import 'package:abigotado_dev/src/features/changelog/widget/changelog_section.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake
// ---------------------------------------------------------------------------

/// An [EffectsStore] that always returns lite mode (cards render hover-inert).
final class _FakeEffectsStore implements EffectsStore {
  const _FakeEffectsStore();

  @override
  EffectsMode? read() => EffectsMode.lite;

  @override
  Future<void> write(EffectsMode mode) async {}

  @override
  Future<void> clear() async {}
}

// ---------------------------------------------------------------------------
// Helper: collect the plain text of every RichText in the tree (Text widgets
// render as RichText internally), concatenated with newlines so assertions can
// use contains() on the whole body.
// ---------------------------------------------------------------------------

String _collectRichText(WidgetTester tester) {
  final richTexts = tester.widgetList<RichText>(find.byType(RichText));
  return richTexts.map((rt) => (rt.text as TextSpan).toPlainText()).join('\n');
}

// ---------------------------------------------------------------------------
// Helper: pump ChangelogSection in a minimal Material/l10n tree at a fixed
// surface size. Mirrors the _pumpCard helper in pubspec_card_test.dart.
// ---------------------------------------------------------------------------

Future<void> _pumpSection(
  WidgetTester tester, {
  required Size surface,
  Locale locale = const Locale('en'),
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        effectsStoreProvider.overrideWithValue(const _FakeEffectsStore()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: ChangelogSection()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ChangelogCard', () {
    // -----------------------------------------------------------------------
    // animation
    // -----------------------------------------------------------------------
    group('animation', () {
      testWidgets(
        'no transient callbacks after pumpAndSettle — section is static',
        (tester) async {
          await _pumpSection(tester, surface: const Size(800, 1200));
          expect(
            tester.binding.transientCallbackCount,
            equals(0),
            reason:
                'ChangelogCard has no animations; '
                'transient callbacks must be zero after pumpAndSettle',
          );
        },
      );
    });

    // -----------------------------------------------------------------------
    // renders the card + version tags (RED on stub — SizedBox.shrink has no
    // text, so version tags won't be found)
    // -----------------------------------------------------------------------
    group('rendering', () {
      testWidgets(
        'ChangelogCard widget is present in the tree',
        (tester) async {
          await _pumpSection(tester, surface: const Size(800, 1200));
          expect(find.byType(ChangelogCard), findsOneWidget);
        },
      );

      testWidgets(
        'all 5 version tags render in the card body',
        (tester) async {
          await _pumpSection(tester, surface: const Size(800, 1200));
          final body = _collectRichText(tester);
          for (final version in ['v5.x', 'v4.x', 'v3.x', 'v2.x', 'v1.0']) {
            expect(
              body,
              contains(version),
              reason: 'version tag "$version" must appear in the rendered body',
            );
          }
        },
      );
    });

    // -----------------------------------------------------------------------
    // i18n — en (RED on stub)
    // -----------------------------------------------------------------------
    group('i18n — en', () {
      testWidgets(
        'career prose renders: crypto + fiat, Digital Technologies, '
        'Russian Railways, breaking change, from editor-in-chief',
        (tester) async {
          await _pumpSection(tester, surface: const Size(800, 1200));
          final body = _collectRichText(tester);
          expect(body, contains('crypto + fiat'));
          expect(body, contains('Digital Technologies'));
          expect(body, contains('Russian Railways'));
          expect(body, contains('breaking change'));
          expect(body, contains('from editor-in-chief'));
        },
      );

      testWidgets(
        'badge "career" is present',
        (tester) async {
          await _pumpSection(tester, surface: const Size(800, 1200));
          expect(find.textContaining('career'), findsAtLeastNWidgets(1));
        },
      );
    });

    // -----------------------------------------------------------------------
    // i18n — ru (RED on stub)
    // -----------------------------------------------------------------------
    group('i18n — ru', () {
      testWidgets(
        'career prose renders: Цифровые технологии, РЖД, из шеф-редактора',
        (tester) async {
          await _pumpSection(
            tester,
            surface: const Size(800, 1200),
            locale: const Locale('ru'),
          );
          final body = _collectRichText(tester);
          expect(body, contains('Цифровые технологии'));
          expect(body, contains('РЖД'));
          expect(body, contains('из шеф-редактора'));
        },
      );

      testWidgets(
        'badge "карьера" is present under ru locale',
        (tester) async {
          await _pumpSection(
            tester,
            surface: const Size(800, 1200),
            locale: const Locale('ru'),
          );
          expect(find.textContaining('карьера'), findsAtLeastNWidgets(1));
        },
      );

      testWidgets(
        'English badge "career" is absent under ru locale',
        (tester) async {
          await _pumpSection(
            tester,
            surface: const Size(800, 1200),
            locale: const Locale('ru'),
          );
          // find.text does exact matching — a standalone badge Text('career')
          // must not appear when the locale is ru.
          expect(find.text('career'), findsNothing);
        },
      );
    });

    // -----------------------------------------------------------------------
    // i18n — es (RED on stub)
    // -----------------------------------------------------------------------
    group('i18n — es', () {
      testWidgets(
        'career prose renders: pipeline de IA, de redactor jefe',
        (tester) async {
          await _pumpSection(
            tester,
            surface: const Size(800, 1200),
            locale: const Locale('es'),
          );
          final body = _collectRichText(tester);
          expect(body, contains('pipeline de IA'));
          expect(body, contains('de redactor jefe'));
        },
      );

      testWidgets(
        'badge "carrera" is present under es locale',
        (tester) async {
          await _pumpSection(
            tester,
            surface: const Size(800, 1200),
            locale: const Locale('es'),
          );
          expect(find.textContaining('carrera'), findsAtLeastNWidgets(1));
        },
      );
    });

    // -----------------------------------------------------------------------
    // Invariant orgs hold across locales (RED on stub)
    // -----------------------------------------------------------------------
    group('invariant orgs', () {
      testWidgets(
        'FinHarbor · Somnio, CPI Technologies, breaking change render in ru',
        (tester) async {
          await _pumpSection(
            tester,
            surface: const Size(800, 1200),
            locale: const Locale('ru'),
          );
          final body = _collectRichText(tester);
          expect(
            body,
            contains('FinHarbor · Somnio'),
            reason:
                'FinHarbor · Somnio is an invariant brand name — '
                'must render identically in ru',
          );
          expect(
            body,
            contains('CPI Technologies'),
            reason:
                'CPI Technologies is an invariant brand name — '
                'must render identically in ru',
          );
          expect(
            body,
            contains('breaking change'),
            reason:
                '"breaking change" is kept English in every locale by design',
          );
        },
      );
    });

    // -----------------------------------------------------------------------
    // Glyph integrity
    // Exact Unicode codepoints:
    //   × U+00D7 MULTIPLICATION SIGN
    //   – U+2013 EN DASH
    // -----------------------------------------------------------------------
    group('glyph integrity', () {
      testWidgets(
        'en: w2 no longer shows the dropped "75 → 40" figure '
        '(résumé sync — numbers match the résumé)',
        (tester) async {
          await _pumpSection(tester, surface: const Size(800, 1200));
          final body = _collectRichText(tester);
          expect(
            body,
            isNot(contains('75 → 40')),
            reason:
                'the résumé dropped the 75→40 MB figure; the changelog must '
                'not reintroduce it (CONCEPT: numbers match the résumé)',
          );
          expect(
            body,
            contains('optimized size & performance'),
            reason: 'w2 now uses the non-numeric résumé phrasing',
          );
        },
      );

      testWidgets(
        'en: "×3–5" (U+00D7 then 3 then U+2013 then 5) renders',
        (tester) async {
          await _pumpSection(tester, surface: const Size(800, 1200));
          final body = _collectRichText(tester);
          // U+00D7 multiplication sign, U+2013 en-dash
          expect(
            body,
            contains('×3–5'),
            reason:
                '"×3–5" must appear with U+00D7 multiplication sign '
                'and U+2013 en-dash',
          );
        },
      );

      testWidgets(
        'en: "perf ×3–5" renders as composed string',
        (tester) async {
          await _pumpSection(tester, surface: const Size(800, 1200));
          final body = _collectRichText(tester);
          expect(
            body,
            contains('perf ×3–5'),
            reason: '"perf ×3–5" must appear as a composed glyph string',
          );
        },
      );
    });

    // -----------------------------------------------------------------------
    // Version-org composed line (RED on stub)
    // The green render joins version + ' — ' (space + U+2014 em-dash + space)
    // + org(l10n).
    // -----------------------------------------------------------------------
    group('version-org composed line', () {
      testWidgets(
        'en: "v4.x — Digital Technologies" renders',
        (tester) async {
          await _pumpSection(tester, surface: const Size(800, 1200));
          final body = _collectRichText(tester);
          // U+2014 EM DASH with surrounding spaces, as per the doc comment
          expect(
            body,
            contains('v4.x — Digital Technologies'),
            reason:
                'version+org label must be joined with " — " '
                '(space + U+2014 em-dash + space)',
          );
        },
      );
    });

    // -----------------------------------------------------------------------
    // a11y — career timeline must NOT exclude semantics
    // (Passes on stub — SizedBox.shrink has no ExcludeSemantics.
    //  Must STAY green after the green pass — that is the point of this test.)
    // -----------------------------------------------------------------------
    group('a11y', () {
      testWidgets(
        'no ExcludeSemantics in the changelog tree — career prose is readable',
        (tester) async {
          final handle = tester.ensureSemantics();

          await _pumpSection(tester, surface: const Size(800, 1200));

          // The career timeline is readable prose — the opposite of
          // PubspecCard's decorative code body. No ExcludeSemantics allowed
          // within the ChangelogSection subtree (scoped to avoid false
          // positives from MaterialApp/Scaffold framework widgets).
          expect(
            find.descendant(
              of: find.byType(ChangelogSection),
              matching: find.byType(ExcludeSemantics),
            ),
            findsNothing,
            reason:
                'career prose must NOT be hidden from screen readers — '
                'ExcludeSemantics must not appear in the changelog subtree',
          );

          handle.dispose();
        },
      );
    });

    // -----------------------------------------------------------------------
    // 320 px narrow layout — no overflow
    // (Passes on stub — SizedBox.shrink does not overflow.)
    // -----------------------------------------------------------------------
    group('narrow layout', () {
      testWidgets(
        '320 px wide — no exception, ChangelogCard is present',
        (tester) async {
          await _pumpSection(
            tester,
            surface: const Size(320, 1000),
          );

          expect(
            tester.takeException(),
            isNull,
            reason: 'no layout exception at 320 px wide',
          );
          expect(find.byType(ChangelogCard), findsOneWidget);
        },
      );
    });
  });
}
