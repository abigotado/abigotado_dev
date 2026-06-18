import 'package:abigotado_dev/src/app/theme/app_theme.dart';
import 'package:abigotado_dev/src/features/metrics/widget/metric_card.dart';
import 'package:abigotado_dev/src/features/metrics/widget/metrics_section.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: MetricsSection()),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('MetricsSection', () {
    group('card count', () {
      testWidgets('renders four MetricCard widgets', (tester) async {
        await _pumpSection(tester, surface: const Size(800, 600));
        expect(find.byType(MetricCard), findsNWidgets(4));
      });
    });

    group('geometry — single column on phone', () {
      testWidgets(
        'surface 360×800 → all four cards share one x-offset (one column)',
        (tester) async {
          await _pumpSection(tester, surface: const Size(360, 800));

          final cards = find.byType(MetricCard);
          final xOffsets = {
            for (var i = 0; i < 4; i++) tester.getTopLeft(cards.at(i)).dx,
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
        'surface 1280×800 → all four cards on one row (4 cols)',
        (tester) async {
          // Net available ≈ 1000−48 = 952 px once ContentWidth caps width;
          // metricsColumnsFor(952) → 4 cols, so all four cards fit on one row.
          await _pumpSection(tester, surface: const Size(1280, 800));

          final cards = find.byType(MetricCard);
          final dys = [
            for (var i = 0; i < 4; i++) tester.getTopLeft(cards.at(i)).dy,
          ];

          // RED: sections still use ConstrainedBox(720) → 3+1 at 1280;
          // green pass swaps MetricsSection to ContentWidth →
          // 4 cols on one row.
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
          expect(
            dys[2],
            equals(dys[3]),
            reason:
                'card 3 must also be on row 1 — '
                'ContentWidth(1000)−48 = 952 fits 4 columns',
          );

          // All four x-offsets must be distinct (four columns, not stacked).
          final xs = {
            for (var i = 0; i < 4; i++) tester.getTopLeft(cards.at(i)).dx,
          };
          expect(
            xs.length,
            equals(4),
            reason: 'four distinct x-offsets → four columns',
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

      testWidgets(
        'app-size card value contains "75 → 40" (U+2192)',
        (tester) async {
          await _pumpSection(tester, surface: const Size(800, 600));
          // U+2192 →
          expect(find.textContaining('75 → 40'), findsOneWidget);
        },
      );

      testWidgets('app-size card value contains "MB"', (tester) async {
        await _pumpSection(tester, surface: const Size(800, 600));
        expect(find.textContaining('MB'), findsOneWidget);
      });

      testWidgets('monorepo card shows "100+ packages"', (tester) async {
        await _pumpSection(tester, surface: const Size(800, 600));
        expect(find.text('100+ packages'), findsOneWidget);
      });

      testWidgets('app size label is present', (tester) async {
        await _pumpSection(tester, surface: const Size(800, 600));
        expect(find.text('app size'), findsOneWidget);
      });

      testWidgets('UI responsiveness label is present', (tester) async {
        await _pumpSection(tester, surface: const Size(800, 600));
        expect(find.text('UI responsiveness'), findsOneWidget);
      });

      testWidgets('monorepo label is present', (tester) async {
        await _pumpSection(tester, surface: const Size(800, 600));
        expect(find.text('monorepo'), findsOneWidget);
      });

      testWidgets('test coverage bar label is present', (tester) async {
        await _pumpSection(tester, surface: const Size(800, 600));
        expect(find.text('test coverage bar'), findsOneWidget);
      });
    });

    group('i18n — ru', () {
      testWidgets('monorepo card shows "100+ пакетов"', (tester) async {
        await _pumpSection(
          tester,
          surface: const Size(800, 600),
          locale: const Locale('ru'),
        );
        expect(find.text('100+ пакетов'), findsOneWidget);
      });

      testWidgets(
        'app-size label shows "размер приложения"',
        (tester) async {
          await _pumpSection(
            tester,
            surface: const Size(800, 600),
            locale: const Locale('ru'),
          );
          expect(find.text('размер приложения'), findsOneWidget);
        },
      );

      testWidgets(
        'English label "app size" is absent under ru locale',
        (tester) async {
          await _pumpSection(
            tester,
            surface: const Size(800, 600),
            locale: const Locale('ru'),
          );
          expect(find.text('app size'), findsNothing);
        },
      );

      testWidgets(
        'app-size card value contains "МБ" (Cyrillic megabyte unit)',
        (tester) async {
          await _pumpSection(
            tester,
            surface: const Size(800, 600),
            locale: const Locale('ru'),
          );
          // ru mb = "МБ"; card1 value = "75 → 40 МБ"
          expect(find.textContaining('МБ'), findsOneWidget);
        },
      );
    });

    group('i18n — es', () {
      testWidgets('monorepo card shows "100+ paquetes"', (tester) async {
        await _pumpSection(
          tester,
          surface: const Size(800, 600),
          locale: const Locale('es'),
        );
        expect(find.text('100+ paquetes'), findsOneWidget);
      });

      testWidgets(
        'app-size label shows "tamaño de la app"',
        (tester) async {
          await _pumpSection(
            tester,
            surface: const Size(800, 600),
            locale: const Locale('es'),
          );
          expect(find.text('tamaño de la app'), findsOneWidget);
        },
      );
    });

    group('a11y — no raw glyphs reach the screen reader', () {
      testWidgets(
        'speed card (index 1) semantics label is glyph-free: '
        'contains "3 to 5 times", excludes × and –',
        (tester) async {
          final handle = tester.ensureSemantics();

          await _pumpSection(tester, surface: const Size(800, 600));

          // Card order: 0=app size, 1=UI responsiveness (×3–5)
          final node = tester.getSemantics(find.byType(MetricCard).at(1));

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
        'app-size card (index 0) semantics label contains "75 to 40", '
        'excludes → (U+2192)',
        (tester) async {
          final handle = tester.ensureSemantics();

          await _pumpSection(tester, surface: const Size(800, 600));

          // Card order: 0=app size
          final node = tester.getSemantics(find.byType(MetricCard).at(0));

          expect(
            node.label,
            contains('75 to 40'),
            reason:
                'app-size card semantics label must include '
                'glyph-free "75 to 40"',
          );
          expect(
            node.label,
            isNot(contains('→')),
            reason: 'U+2192 → must not appear in the screen-reader label',
          );

          handle.dispose();
        },
      );
    });
  });
}
