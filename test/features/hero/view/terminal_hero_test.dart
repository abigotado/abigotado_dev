import 'dart:async';

import 'package:abigotado_dev/src/app/theme/app_theme.dart';
import 'package:abigotado_dev/src/core/clock/scenario_clock.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/core/effects/effects_store.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/features/hero/state/build_scenario_notifier.dart';
import 'package:abigotado_dev/src/features/hero/view/terminal_hero.dart';
import 'package:abigotado_dev/src/features/hero/widget/skip_button.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake clock
// ---------------------------------------------------------------------------

/// Controllable clock — [advance] resolves one pending [elapse] per call.
final class _FakeScenarioClock implements ScenarioClock {
  final List<Completer<void>> _queue = [];

  Future<void> advance() async {
    if (_queue.isEmpty) return; // guard: start() may have been skipped
    _queue.removeAt(0).complete();
    await Future<void>.value();
  }

  @override
  Future<void> elapse(Duration duration) {
    final completer = Completer<void>();
    _queue.add(completer);
    return completer.future;
  }
}

// ---------------------------------------------------------------------------
// Fake effects store
// ---------------------------------------------------------------------------

/// Returns the given [stored] mode; writes/clears are no-ops.
final class _FakeEffectsStore implements EffectsStore {
  const _FakeEffectsStore({this.stored});

  final EffectsMode? stored;

  @override
  EffectsMode? read() => stored;

  @override
  Future<void> write(EffectsMode mode) async {}

  @override
  Future<void> clear() async {}
}

// ---------------------------------------------------------------------------
// Helper: pump TerminalHero in a minimal Material/l10n tree.
//
// [effectsStore] and [mediaQueryData] are required and must come first
// (required named params before optional).
// [locale] defaults to en; [clock] is optional (supply for full-mode tests).
// ---------------------------------------------------------------------------

Future<void> _pumpHero(
  WidgetTester tester, {
  required MediaQueryData mediaQueryData,
  required EffectsStore effectsStore,
  Locale locale = const Locale('en'),
  ScenarioClock? clock,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  // Build the override list dynamically so the clock is only injected when
  // supplied. Let Dart infer the element type from the values.
  final overrides = [
    effectsStoreProvider.overrideWithValue(effectsStore),
    if (clock != null) scenarioClockProvider.overrideWithValue(clock),
  ];

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: mediaQueryData,
          child: const Scaffold(body: TerminalHero()),
        ),
      ),
    ),
  );
}

/// Wide-viewport [MediaQueryData] with no reduced-motion signal.
///
/// When combined with [_FakeEffectsStore(stored: EffectsMode.lite)] the
/// manual choice wins and the hero enters lite mode regardless of viewport.
const MediaQueryData _liteMediaQuery = MediaQueryData(size: Size(800, 900));

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('TerminalHero', () {
    // -----------------------------------------------------------------------
    group('lite mode — static released frame', () {
      testWidgets(
        'effects=lite → skip() called → released frame: '
        'all agent lines _DoneLine, revtext_done visible, '
        'RELEASE banner, no SkipButton, no running timers',
        (tester) async {
          await _pumpHero(
            tester,
            mediaQueryData: _liteMediaQuery,
            effectsStore: const _FakeEffectsStore(stored: EffectsMode.lite),
          );
          // lite → skip() → released; pumpAndSettle is safe here because no
          // AnimationControllers are allocated in lite mode.
          await tester.pumpAndSettle();

          // All three agent lines must be _DoneLine — each renders Icons.check.
          // _PendingLine/_RunningLine use Icons.fiber_manual_record instead.
          expect(
            find.byIcon(Icons.check),
            findsNWidgets(3),
            reason: 'All 3 agent lines must be _DoneLine in released state',
          );

          // Reviewer card shows approved body (revtext_done), not nitpick body.
          final l10n = AppLocalizations.of(
            tester.element(find.byType(TerminalHero)),
          );
          expect(find.text(l10n.revtext_done), findsOneWidget);
          expect(find.text(l10n.revtext_run), findsNothing);

          // Banner widget message must be RELEASE (not DEBUG).
          final banners = tester.widgetList<Banner>(find.byType(Banner));
          expect(
            banners.any((b) => b.message == 'RELEASE'),
            isTrue,
            reason: 'DebugReleaseBanner must show RELEASE when released',
          );

          // SkipButton is hidden once released.
          expect(find.byType(SkipButton), findsNothing);

          // No persistent animation callbacks: lite mode allocates no tickers.
          expect(tester.binding.transientCallbackCount, equals(0));
        },
      );

      testWidgets(
        r'lite mode — $ agents build abigotado.dev --release command renders',
        (tester) async {
          await _pumpHero(
            tester,
            mediaQueryData: _liteMediaQuery,
            effectsStore: const _FakeEffectsStore(stored: EffectsMode.lite),
          );
          await tester.pumpAndSettle();

          expect(
            find.textContaining(
              r'$ agents build abigotado.dev --release',
            ),
            findsOneWidget,
          );
        },
      );
    });

    // -----------------------------------------------------------------------
    group('full mode — clock-driven transitions', () {
      testWidgets(
        'effects=full, initial pump → SkipButton visible, DEBUG banner',
        (tester) async {
          final clock = _FakeScenarioClock();
          await _pumpHero(
            tester,
            mediaQueryData: const MediaQueryData(size: Size(800, 900)),
            effectsStore: const _FakeEffectsStore(stored: EffectsMode.full),
            clock: clock,
          );
          // Single pump only — do NOT pumpAndSettle: spinner/cursor controllers
          // repeat forever and would cause pumpAndSettle to time out.
          await tester.pump();

          // SkipButton appears while the scenario is still running.
          expect(find.byType(SkipButton), findsOneWidget);

          // Banner reads DEBUG before release.
          final banners = tester.widgetList<Banner>(find.byType(Banner));
          expect(banners.any((b) => b.message == 'DEBUG'), isTrue);
        },
      );

      testWidgets(
        'effects=full — advance all phases → RELEASE, revtext_done, '
        'SkipButton gone',
        (tester) async {
          final clock = _FakeScenarioClock();
          await _pumpHero(
            tester,
            mediaQueryData: const MediaQueryData(size: Size(800, 900)),
            effectsStore: const _FakeEffectsStore(stored: EffectsMode.full),
            clock: clock,
          );
          await tester.pump();

          await clock.advance(); // planning → coding
          await tester.pump();
          await clock.advance(); // coding → reviewing
          await tester.pump();
          await clock.advance(); // reviewing → released
          await tester.pump();
          // Settle the 250ms DEBUG→RELEASE crossfade added in the green pass.
          // In contracts (instant banner) this pump is a harmless no-op.
          await tester.pump(const Duration(milliseconds: 300));

          final l10n = AppLocalizations.of(
            tester.element(find.byType(TerminalHero)),
          );
          expect(find.text(l10n.revtext_done), findsOneWidget);
          expect(find.text(l10n.revtext_run), findsNothing);

          final banners = tester.widgetList<Banner>(find.byType(Banner));
          expect(banners.any((b) => b.message == 'RELEASE'), isTrue);
          expect(find.byType(SkipButton), findsNothing);
        },
      );

      testWidgets(
        'effects=full — tapping SkipButton → released frame immediately',
        (tester) async {
          final clock = _FakeScenarioClock();
          await _pumpHero(
            tester,
            mediaQueryData: const MediaQueryData(size: Size(800, 900)),
            effectsStore: const _FakeEffectsStore(stored: EffectsMode.full),
            clock: clock,
          );
          await tester.pump();

          expect(find.byType(SkipButton), findsOneWidget);

          await tester.tap(find.byType(SkipButton));
          await tester.pump();
          // Settle the 250ms DEBUG→RELEASE crossfade added in the green pass.
          // In contracts (instant banner) this pump is a harmless no-op.
          await tester.pump(const Duration(milliseconds: 300));

          final l10n = AppLocalizations.of(
            tester.element(find.byType(TerminalHero)),
          );
          expect(find.text(l10n.revtext_done), findsOneWidget);
          final banners = tester.widgetList<Banner>(find.byType(Banner));
          expect(banners.any((b) => b.message == 'RELEASE'), isTrue);
          expect(find.byType(SkipButton), findsNothing);
        },
      );
    });

    // -----------------------------------------------------------------------
    group('agent-line sealed variants', () {
      testWidgets(
        'planning phase → 0 check icons '
        '(planner running, coder+reviewer pending)',
        (tester) async {
          final clock = _FakeScenarioClock();
          await _pumpHero(
            tester,
            mediaQueryData: const MediaQueryData(size: Size(800, 900)),
            effectsStore: const _FakeEffectsStore(stored: EffectsMode.full),
            clock: clock,
          );
          await tester.pump();

          expect(find.byIcon(Icons.check), findsNothing);
        },
      );

      testWidgets(
        'reviewing phase → 2 check icons (planner+coder done), '
        'reviewer is _RunningLine (no check icon for reviewer)',
        (tester) async {
          final clock = _FakeScenarioClock();
          await _pumpHero(
            tester,
            mediaQueryData: const MediaQueryData(size: Size(800, 900)),
            effectsStore: const _FakeEffectsStore(stored: EffectsMode.full),
            clock: clock,
          );
          await tester.pump();

          await clock.advance(); // planning → coding
          await tester.pump();
          await clock.advance(); // coding → reviewing
          await tester.pump();

          expect(
            find.byIcon(Icons.check),
            findsNWidgets(2),
            reason: 'planner and coder must be _DoneLine in reviewing phase',
          );
        },
      );

      testWidgets(
        'released phase → 3 check icons (all agents _DoneLine)',
        (tester) async {
          final clock = _FakeScenarioClock();
          await _pumpHero(
            tester,
            mediaQueryData: const MediaQueryData(size: Size(800, 900)),
            effectsStore: const _FakeEffectsStore(stored: EffectsMode.full),
            clock: clock,
          );
          await tester.pump();

          await clock.advance(); // planning → coding
          await tester.pump();
          await clock.advance(); // coding → reviewing
          await tester.pump();
          await clock.advance(); // reviewing → released
          await tester.pump();

          expect(find.byIcon(Icons.check), findsNWidgets(3));
        },
      );
    });

    // -----------------------------------------------------------------------
    group('localization', () {
      testWidgets(
        'locale=ru, lite → rev_done and revtext_done render in Russian',
        (tester) async {
          await _pumpHero(
            tester,
            locale: const Locale('ru'),
            mediaQueryData: _liteMediaQuery,
            effectsStore: const _FakeEffectsStore(stored: EffectsMode.lite),
          );
          await tester.pumpAndSettle();

          // Released state: reviewer line shows rev_done in Russian.
          expect(
            find.text('одобрено: human-grade quality'),
            findsOneWidget,
          );
          // Approved card body in Russian.
          expect(
            find.text('«Теперь честно. Одобрено — отправляю в RELEASE.»'),
            findsOneWidget,
          );
          // Nitpick text must not appear.
          expect(find.text('придирается'), findsNothing);
        },
      );

      testWidgets(
        'locale=es, lite → rev_done and revtext_done render in Spanish',
        (tester) async {
          await _pumpHero(
            tester,
            locale: const Locale('es'),
            mediaQueryData: _liteMediaQuery,
            effectsStore: const _FakeEffectsStore(stored: EffectsMode.lite),
          );
          await tester.pumpAndSettle();

          expect(find.text('aprobado: calidad humana'), findsOneWidget);
          expect(
            find.text('«Ahora sí es honesto. Aprobado — a RELEASE.»'),
            findsOneWidget,
          );
          expect(find.text('poniendo pegas'), findsNothing);
        },
      );

      testWidgets(
        'locale=en, full, reviewing phase → "nitpicking" rev_run, '
        'revtext_run body visible',
        (tester) async {
          final clock = _FakeScenarioClock();
          await _pumpHero(
            tester,
            mediaQueryData: const MediaQueryData(size: Size(800, 900)),
            effectsStore: const _FakeEffectsStore(stored: EffectsMode.full),
            clock: clock,
          );
          await tester.pump();

          await clock.advance(); // planning → coding
          await tester.pump();
          await clock.advance(); // coding → reviewing
          await tester.pump();

          expect(find.text('nitpicking'), findsOneWidget);
          // Retargeted gag references the real metric (10K+ downloads), not
          // the removed "100+ package monorepo".
          expect(find.textContaining('10K+ downloads'), findsOneWidget);
          expect(find.textContaining('100+ package'), findsNothing);
        },
      );

      testWidgets(
        'locale=ru, full, reviewing phase → "придирается" rev_run',
        (tester) async {
          final clock = _FakeScenarioClock();
          await _pumpHero(
            tester,
            locale: const Locale('ru'),
            mediaQueryData: const MediaQueryData(size: Size(800, 900)),
            effectsStore: const _FakeEffectsStore(stored: EffectsMode.full),
            clock: clock,
          );
          await tester.pump();

          await clock.advance(); // planning → coding
          await tester.pump();
          await clock.advance(); // coding → reviewing
          await tester.pump();

          expect(find.text('придирается'), findsOneWidget);
        },
      );
    });
  });
}
