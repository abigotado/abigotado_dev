import 'package:abigotado_dev/src/app/theme/app_theme.dart';
import 'package:abigotado_dev/src/app/view/editor_pane.dart';
import 'package:abigotado_dev/src/app/view/landing_page.dart';
import 'package:abigotado_dev/src/app/widget/editor_file.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/core/effects/effects_store.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/features/hero/widget/terminal_frame.dart';
import 'package:abigotado_dev/src/features/metrics/widget/metrics_section.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Guards for TerminalFrame's right-flush layout (implemented in the stage-2
// contracts commit — see its class doc). Every assertion pins the documented
// geometry against regression.
//
// The harness pumps the REAL production hierarchy —
// EditorPane → SingleChildScrollView → LandingPage → … → TerminalHero →
// TerminalFrame — NOT a bare TerminalFrame. An earlier version of this suite
// pumped the frame directly and stayed green while the real tree was 24 px
// off: TerminalHero wrapped the frame in an extra horizontal padding that
// shifted the whole ContentWidth column relative to the cards. Geometry
// guards are only honest against the tree users actually see.
// ---------------------------------------------------------------------------

final class _LiteEffectsStore implements EffectsStore {
  const _LiteEffectsStore();

  @override
  EffectsMode? read() => EffectsMode.lite;

  @override
  Future<void> write(EffectsMode mode) async {}

  @override
  Future<void> clear() async {}
}

// Pumps the real landing tree inside EditorPane — the same wrapping the
// editor shell applies in production. Lite: the hero renders its static
// released frame, so pumpAndSettle is safe.
Future<void> _pumpLanding(
  WidgetTester tester, {
  required Size surface,
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        effectsStoreProvider.overrideWithValue(const _LiteEffectsStore()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: EditorPane(
            child: SingleChildScrollView(
              child: LandingPage(
                sectionKeys: {
                  for (final f in EditorFile.values) f: GlobalKey(),
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('TerminalFrame', () {
    group('right-flush against the metrics Wrap (real landing tree)', () {
      testWidgets(
        '1280×900 surface → panel right edge flush with the metrics Wrap '
        'right edge, panel left edge indented past the Wrap left edge',
        (tester) async {
          await _pumpLanding(tester, surface: const Size(1280, 900));

          final panelTopRight = tester.getTopRight(
            find.byKey(TerminalFrame.panelKey),
          );
          final panelTopLeft = tester.getTopLeft(
            find.byKey(TerminalFrame.panelKey),
          );
          final wrapFinder = find.descendant(
            of: find.byType(MetricsSection),
            matching: find.byType(Wrap),
          );
          final wrapTopRight = tester.getTopRight(wrapFinder);
          final wrapTopLeft = tester.getTopLeft(wrapFinder);

          expect(
            panelTopRight.dx,
            closeTo(wrapTopRight.dx, 0.5),
            reason:
                'the terminal panel and the metrics Wrap both cap at '
                'AppSizing.contentMaxWidth — their right edges must be '
                'flush in the REAL tree (TerminalHero must not add '
                'horizontal padding around the frame)',
          );
          expect(
            panelTopLeft.dx,
            greaterThan(wrapTopLeft.dx),
            reason:
                'the panel indents from the LEFT on wide viewports — the '
                'deliberate ragged-left, flush-right layout (TerminalFrame '
                'class doc)',
          );
        },
      );

      testWidgets(
        '360×900 surface → panel and metrics Wrap share both edges '
        '(flush is a no-op below AppSizing.contentMaxWidth)',
        (tester) async {
          await _pumpLanding(tester, surface: const Size(360, 900));

          final panelTopRight = tester.getTopRight(
            find.byKey(TerminalFrame.panelKey),
          );
          final panelTopLeft = tester.getTopLeft(
            find.byKey(TerminalFrame.panelKey),
          );
          final wrapFinder = find.descendant(
            of: find.byType(MetricsSection),
            matching: find.byType(Wrap),
          );
          final wrapTopRight = tester.getTopRight(wrapFinder);
          final wrapTopLeft = tester.getTopLeft(wrapFinder);

          expect(
            panelTopRight.dx,
            closeTo(wrapTopRight.dx, 0.5),
            reason:
                'below the cap both widgets fill the same available '
                'width, so the right edges still match',
          );
          expect(
            panelTopLeft.dx,
            closeTo(wrapTopLeft.dx, 0.5),
            reason:
                'below the cap the ragged-left indent collapses to zero '
                '— both left edges match too',
          );
        },
      );
    });
  });
}
