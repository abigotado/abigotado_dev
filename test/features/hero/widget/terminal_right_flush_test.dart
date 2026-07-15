import 'package:abigotado_dev/src/app/theme/app_theme.dart';
import 'package:abigotado_dev/src/app/view/editor_pane.dart';
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
// BORN-GREEN GUARDS. `TerminalFrame`'s right-flush layout is already real,
// implemented production code as of the stage-2 contracts commit (see its
// class doc) — nothing here is stubbed. Every assertion below passes on the
// current tree and must STAY green through the coder's green pass; they pin
// the documented geometry against a future regression.
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Fake
// ---------------------------------------------------------------------------

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
// Helper: pump TerminalFrame stacked above MetricsSection inside EditorPane —
// the same nesting `EditorScrollHost`'s real section list uses (both widgets
// are direct children of one Column, wrapped once by EditorPane). Mirrors
// metrics_section_test.dart's `_pumpSection`.
//
// TerminalFrame's own `children` is a single `SizedBox(width:
// double.infinity)` filler. Per TerminalFrame's class doc ("The load-bearing
// width mechanism"), it is `ReviewerCommentCard`'s `width: double.infinity`
// that forces the panel's Column to fill the `AppSizing.terminalMaxWidth` cap
// (or, below the cap, the full available content width) instead of
// shrink-wrapping to the command line's intrinsic width — without it the
// panel would be narrower than the metrics Wrap at narrow surface widths and
// the "share both edges below the cap" guard below would not hold. A minimal
// `SizedBox` reproduces that exact mechanism without pulling in
// `ReviewerCommentCard`'s own `buildScenarioProvider` coupling, which this
// pure geometry suite has no need for.
// ---------------------------------------------------------------------------

Future<void> _pumpSection(
  WidgetTester tester, {
  required Size surface,
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: EditorPane(
            child: Column(
              children: [
                TerminalFrame(
                  children: [SizedBox(width: double.infinity, height: 1)],
                ),
                MetricsSection(),
              ],
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
    group('right-flush against the metrics Wrap', () {
      testWidgets(
        '1280×900 surface → panel right edge flush with the metrics Wrap '
        'right edge, panel left edge indented past the Wrap left edge',
        (tester) async {
          await _pumpSection(tester, surface: const Size(1280, 900));

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
                'AppSizing.contentMaxWidth — their right edges must be flush',
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
          await _pumpSection(tester, surface: const Size(360, 900));

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
