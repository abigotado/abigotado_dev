import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/core/effects/effects_store.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/features/hero/state/build_scenario_notifier.dart';
import 'package:abigotado_dev/src/features/hero/state/build_scenario_state.dart';
import 'package:abigotado_dev/src/features/hero/widget/debug_release_banner.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake effects store — returns a fixed stored mode; writes/clears are no-ops.
// ---------------------------------------------------------------------------

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
// Fake scenario notifier — holds a fixed initial state, exposes release().
// Local to this file; do NOT extract to a shared support file.
// ---------------------------------------------------------------------------

final class _FixedScenarioNotifier extends BuildScenarioNotifier {
  _FixedScenarioNotifier(this._initial);

  final BuildScenarioState _initial;

  @override
  BuildScenarioState build() => _initial;

  void release() => state = const BuildScenarioState.released();
}

// ---------------------------------------------------------------------------
// Helper: pump DebugReleaseBanner(child: SizedBox()) in isolation.
//
// Returns ProviderContainer so tests can drive the notifier.
// Surface defaults to 800×600 (non-compact → full when store has no choice).
// ---------------------------------------------------------------------------

Future<ProviderContainer> _pumpBanner(
  WidgetTester tester, {
  required EffectsStore effectsStore,
  required BuildScenarioState initialScenario,
  Size surfaceSize = const Size(800, 600),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final container = ProviderContainer(
    overrides: [
      effectsStoreProvider.overrideWithValue(effectsStore),
      buildScenarioProvider.overrideWith(
        () => _FixedScenarioNotifier(initialScenario),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(size: surfaceSize),
          child: const Scaffold(
            body: DebugReleaseBanner(child: SizedBox()),
          ),
        ),
      ),
    ),
  );

  return container;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('DebugReleaseBanner', () {
    // -------------------------------------------------------------------------
    group('released → RELEASE banner', () {
      // REGRESSION GUARD: the current instant-switch implementation already
      // shows RELEASE/green. Must stay green through the green pass.
      testWidgets(
        'lite, released → one Banner, message==RELEASE, color==accentGreen',
        (tester) async {
          await _pumpBanner(
            tester,
            effectsStore: const _FakeEffectsStore(stored: EffectsMode.lite),
            initialScenario: const BuildScenarioState.released(),
          );
          await tester.pump();

          final banners = tester
              .widgetList<Banner>(find.byType(Banner))
              .toList();
          expect(banners, hasLength(1));
          expect(banners.first.message, equals('RELEASE'));
          expect(banners.first.color, equals(AppColors.accentGreen));
        },
      );
    });

    // -------------------------------------------------------------------------
    group('building → DEBUG banner', () {
      // REGRESSION GUARD: instant-switch shows DEBUG/red when not released.
      // Must stay green through the green pass.
      testWidgets(
        'lite, planning → one Banner, message==DEBUG, color==accentRed',
        (tester) async {
          await _pumpBanner(
            tester,
            effectsStore: const _FakeEffectsStore(stored: EffectsMode.lite),
            initialScenario: const BuildScenarioState.initial(),
          );
          await tester.pump();

          final banners = tester
              .widgetList<Banner>(find.byType(Banner))
              .toList();
          expect(banners, hasLength(1));
          expect(banners.first.message, equals('DEBUG'));
          expect(banners.first.color, equals(AppColors.accentRed));
        },
      );
    });

    // -------------------------------------------------------------------------
    group('lite → no ticker', () {
      // REGRESSION GUARD: lite mode must allocate no animation controllers.
      testWidgets(
        'lite, released → pumpAndSettle clean, zero transient callbacks',
        (tester) async {
          await _pumpBanner(
            tester,
            effectsStore: const _FakeEffectsStore(stored: EffectsMode.lite),
            initialScenario: const BuildScenarioState.released(),
          );
          await tester.pumpAndSettle();

          expect(tester.binding.transientCallbackCount, equals(0));
        },
      );
    });

    // -------------------------------------------------------------------------
    group('full → crossfade', () {
      // RED: the current DebugReleaseBanner uses an instant inline switch with
      // no BuildTagTransition, so no controller is ever created.
      //
      // After the green pass wraps it in BuildTagTransition:
      //   1. First pump (planning): Banner message==DEBUG, no ticker yet.
      //   2. .release() + pump: ticker running (forward() called).
      //   3. pump(300ms): Banner message==RELEASE/green, ticker done.
      testWidgets(
        'full store, planning: DEBUG, no ticker; '
        'release() → ticker running; 300ms → RELEASE/green, done',
        (tester) async {
          // Wide viewport, no manual choice → effectsModeOf resolves full.
          final container = await _pumpBanner(
            tester,
            effectsStore: const _FakeEffectsStore(),
            initialScenario: const BuildScenarioState.initial(),
          );
          await tester.pump();

          // Phase=planning → DEBUG banner.
          // PASSES now (instant switch returns DEBUG).
          final bannersBefore = tester
              .widgetList<Banner>(find.byType(Banner))
              .toList();
          expect(bannersBefore, hasLength(1));
          expect(bannersBefore.first.message, equals('DEBUG'));
          // Lazy controller — no ticker before transition starts.
          expect(tester.binding.transientCallbackCount, equals(0));

          // Drive the notifier to released.
          (container.read(buildScenarioProvider.notifier)
                  as _FixedScenarioNotifier)
              .release();
          await tester.pump();

          // RED: no controller in stub → transientCallbackCount stays 0.
          expect(tester.binding.transientCallbackCount, greaterThan(0));

          // Settle past 250ms crossfade.
          await tester.pump(const Duration(milliseconds: 300));

          final bannersAfter = tester
              .widgetList<Banner>(find.byType(Banner))
              .toList();
          expect(bannersAfter, hasLength(1));
          expect(bannersAfter.first.message, equals('RELEASE'));
          expect(bannersAfter.first.color, equals(AppColors.accentGreen));
          expect(tester.binding.transientCallbackCount, equals(0));
        },
      );
    });
  });
}
