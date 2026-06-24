import 'package:abigotado_dev/src/app/theme/app_theme.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/core/effects/effects_store.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/features/metrics/widget/metric_card.dart';
import 'package:abigotado_dev/src/features/metrics/widget/metrics_section.dart';
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
// Helper: pump MetricsSection in a minimal Material/l10n tree at a fixed size.
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
        home: const Scaffold(body: MetricsSection()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
//
// Card order (matches the résumé sync): 0 = UI responsiveness (×3–5),
// 1 = test coverage (70–75%), 2 = downloads (10K+).
// ---------------------------------------------------------------------------

void main() {
  group('MetricsSection', () {
    group('card count', () {
      testWidgets('renders three MetricCard widgets', (tester) async {
        await _pumpSection(tester, surface: const Size(800, 600));
        expect(find.byType(MetricCard), findsNWidgets(3));
      });
    });

    group('geometry — single column on phone', () {
      testWidgets(
        'surface 360×800 → all three cards share one x-offset (one column)',
        (tester) async {
          await _pumpSection(tester, surface: const Size(360, 800));

          final cards = find.byType(MetricCard);
          final xOffsets = {
            for (var i = 0; i < 3; i++) tester.getTopLeft(cards.at(i)).dx,
          };

          expect(
            xOffsets.length,
            equals(1),
            reason: 'phone width → exactly one column',
          );
        },
      );
    });

    group('geometry — multi-column on wide surface', () {
      testWidgets(
        'surface 1280×800 → all three cards on one row (3 cols)',
        (tester) async {
          // Net available ≈ 1000−48 = 952 px once ContentWidth caps width;
          // metricsColumnsFor(952) → 4, but the column count is capped at the
          // card count (3), so the three cards fill one row evenly.
          await _pumpSection(tester, surface: const Size(1280, 800));

          final cards = find.byType(MetricCard);
          final dys = [
            for (var i = 0; i < 3; i++) tester.getTopLeft(cards.at(i)).dy,
          ];

          expect(
            dys[0],
            equals(dys[1]),
            reason: 'cards 0 and 1 must share the same row top-offset',
          );
          expect(
            dys[1],
            equals(dys[2]),
            reason: 'cards 1 and 2 must share the same row top-offset',
          );

          // All three x-offsets must be distinct (three columns, not stacked).
          final xs = {
            for (var i = 0; i < 3; i++) tester.getTopLeft(cards.at(i)).dx,
          };
          expect(
            xs.length,
            equals(3),
            reason: 'three distinct x-offsets → three columns',
          );
        },
      );
    });

    group('animation', () {
      testWidgets(
        'no transient callbacks after pumpAndSettle — section is static',
        (tester) async {
          await _pumpSection(tester, surface: const Size(800, 600));
          expect(
            tester.binding.transientCallbackCount,
            equals(0),
            reason:
                'MetricsSection has no animations; '
                'transient callbacks must be zero',
          );
        },
      );
    });

    group('i18n — en', () {
      testWidgets('speed card shows ×3–5 (U+00D7, U+2013)', (tester) async {
        await _pumpSection(tester, surface: const Size(800, 600));
        // U+00D7 × followed by "3", U+2013 –, "5"
        expect(find.text('×3–5'), findsOneWidget);
      });

      testWidgets('coverage card shows 70–75% (U+2013)', (tester) async {
        await _pumpSection(tester, surface: const Size(800, 600));
        // U+2013 –
        expect(find.text('70–75%'), findsOneWidget);
      });

      testWidgets('downloads card shows 10K+ (ASCII-only)', (tester) async {
        await _pumpSection(tester, surface: const Size(800, 600));
        expect(find.text('10K+'), findsOneWidget);
      });

      testWidgets('UI responsiveness label is present', (tester) async {
        await _pumpSection(tester, surface: const Size(800, 600));
        expect(find.text('UI responsiveness'), findsOneWidget);
      });

      testWidgets('test coverage bar label is present', (tester) async {
        await _pumpSection(tester, surface: const Size(800, 600));
        expect(find.text('test coverage bar'), findsOneWidget);
      });

      testWidgets('downloads label is present', (tester) async {
        await _pumpSection(tester, surface: const Size(800, 600));
        expect(find.text('downloads'), findsOneWidget);
      });

      testWidgets('removed metrics are absent (app size, monorepo)', (
        tester,
      ) async {
        await _pumpSection(tester, surface: const Size(800, 600));
        expect(find.text('app size'), findsNothing);
        expect(find.text('monorepo'), findsNothing);
        expect(find.text('100+ packages'), findsNothing);
      });
    });

    group('i18n — ru', () {
      testWidgets('downloads label shows "загрузки"', (tester) async {
        await _pumpSection(
          tester,
          surface: const Size(800, 600),
          locale: const Locale('ru'),
        );
        expect(find.text('загрузки'), findsOneWidget);
      });

      testWidgets(
        'coverage label shows "планка тестов"',
        (tester) async {
          await _pumpSection(
            tester,
            surface: const Size(800, 600),
            locale: const Locale('ru'),
          );
          expect(find.text('планка тестов'), findsOneWidget);
        },
      );

      testWidgets(
        'English label "downloads" is absent under ru locale',
        (tester) async {
          await _pumpSection(
            tester,
            surface: const Size(800, 600),
            locale: const Locale('ru'),
          );
          expect(find.text('downloads'), findsNothing);
        },
      );
    });

    group('i18n — es', () {
      testWidgets('downloads label shows "descargas"', (tester) async {
        await _pumpSection(
          tester,
          surface: const Size(800, 600),
          locale: const Locale('es'),
        );
        expect(find.text('descargas'), findsOneWidget);
      });

      testWidgets(
        'coverage label shows "listón de tests"',
        (tester) async {
          await _pumpSection(
            tester,
            surface: const Size(800, 600),
            locale: const Locale('es'),
          );
          expect(find.text('listón de tests'), findsOneWidget);
        },
      );
    });

    group('a11y — no raw glyphs reach the screen reader', () {
      testWidgets(
        'speed card (index 0) semantics label is glyph-free: '
        'contains "3 to 5 times", excludes × and –',
        (tester) async {
          final handle = tester.ensureSemantics();

          await _pumpSection(tester, surface: const Size(800, 600));

          // Card order: 0 = UI responsiveness (×3–5)
          final node = tester.getSemantics(find.byType(MetricCard).at(0));

          expect(
            node.label,
            contains('3 to 5 times'),
            reason:
                'speed card semantics label must include '
                'glyph-free "3 to 5 times"',
          );
          expect(
            node.label,
            isNot(contains('×')),
            reason: 'U+00D7 × must not appear in the screen-reader label',
          );
          expect(
            node.label,
            isNot(contains('–')),
            reason: 'U+2013 – must not appear in the screen-reader label',
          );

          handle.dispose();
        },
      );

      testWidgets(
        'downloads card (index 2) semantics label spells out the figure: '
        'contains "over 10 thousand downloads", excludes the raw "10K+"',
        (tester) async {
          final handle = tester.ensureSemantics();

          await _pumpSection(tester, surface: const Size(800, 600));

          // Card order: 2 = downloads (10K+)
          final node = tester.getSemantics(find.byType(MetricCard).at(2));

          expect(
            node.label,
            contains('over 10 thousand downloads'),
            reason:
                'downloads card semantics label must spell out the figure '
                'glyph-free',
          );
          expect(
            node.label,
            isNot(contains('10K+')),
            reason:
                'the decorative "10K+" value must be excluded from the '
                'screen-reader label (ExcludeSemantics)',
          );

          handle.dispose();
        },
      );
    });
  });
}
