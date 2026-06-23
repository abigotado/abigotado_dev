import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/core/effects/effects_store.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/features/hero/state/build_scenario_notifier.dart';
import 'package:abigotado_dev/src/features/hero/state/build_scenario_state.dart';
import 'package:abigotado_dev/src/features/hero/widget/release_tag.dart';
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
// Helper: pump ReleaseTag in isolation with a minimal Material/l10n tree.
//
// Uses ProviderContainer + UncontrolledProviderScope so tests can read the
// notifier directly. The container is returned for cross-fade tests.
// Surface defaults to 800×600 (non-compact, >600px, so effectsModeOf→full
// when the store has no manual choice).
// ---------------------------------------------------------------------------

Future<ProviderContainer> _pumpTag(
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
          child: const Scaffold(body: ReleaseTag()),
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
  group('ReleaseTag', () {
    // -------------------------------------------------------------------------
    group('released → RELEASE', () {
      // REGRESSION GUARD: the placeholder always shows RELEASE, so this passes
      // now. It must stay green through the green pass too.
      testWidgets(
        'released → RELEASE text present, no DEBUG text',
        (tester) async {
          await _pumpTag(
            tester,
            effectsStore: const _FakeEffectsStore(stored: EffectsMode.lite),
            initialScenario: const BuildScenarioState.released(),
          );
          await tester.pump();

          expect(find.text('RELEASE'), findsOneWidget);
          expect(find.textContaining('DEBUG'), findsNothing);
        },
      );
    });

    // -------------------------------------------------------------------------
    group('building → DEBUG', () {
      // RED: placeholder ignores phase and always shows RELEASE.
      // Fails until the green pass reads phase and shows DEBUG.
      testWidgets(
        'planning → DEBUG text present, no RELEASE text',
        (tester) async {
          await _pumpTag(
            tester,
            effectsStore: const _FakeEffectsStore(stored: EffectsMode.lite),
            initialScenario: const BuildScenarioState.initial(),
          );
          await tester.pump();

          expect(find.text('DEBUG'), findsOneWidget);
          expect(find.text('RELEASE'), findsNothing);
        },
      );
    });

    // -------------------------------------------------------------------------
    group('lite → no ticker', () {
      // REGRESSION GUARD: lite store + no controller → zero transient
      // callbacks. Passes now; must stay green in the green pass.
      testWidgets(
        'lite, released → pumpAndSettle clean, RELEASE shown, zero callbacks',
        (tester) async {
          await _pumpTag(
            tester,
            effectsStore: const _FakeEffectsStore(stored: EffectsMode.lite),
            initialScenario: const BuildScenarioState.released(),
          );
          await tester.pumpAndSettle();

          expect(find.text('RELEASE'), findsOneWidget);
          expect(tester.binding.transientCallbackCount, equals(0));
        },
      );
    });

    // -------------------------------------------------------------------------
    group('full → crossfade DEBUG→RELEASE', () {
      // RED: the stub BuildTagTransition returns builder(context, 0) with no
      // controller and no ref.listen. After .release() the notifier changes
      // but no ticker is created → transientCallbackCount stays 0. Also the
      // placeholder ignores phase → always shows RELEASE, never DEBUG.
      //
      // This test fails on TWO counts:
      //   1. First pump: expect DEBUG → placeholder shows RELEASE instead.
      //   2. After release(): transientCallbackCount stays 0 (no forward()).
      testWidgets(
        'full store, planning: DEBUG, no ticker; '
        'release() → ticker running; 300ms → RELEASE, done',
        (tester) async {
          // Wide viewport (800px > kCompactWidth=600), no manual choice →
          // effectsModeOf resolves to full.
          final container = await _pumpTag(
            tester,
            effectsStore: const _FakeEffectsStore(),
            initialScenario: const BuildScenarioState.initial(),
          );
          await tester.pump();

          // Before release: phase=planning → tag must read DEBUG.
          // RED now: placeholder shows RELEASE regardless.
          expect(find.text('DEBUG'), findsOneWidget);
          // Controller is lazy — no ticker until the transition starts.
          expect(tester.binding.transientCallbackCount, equals(0));

          // Drive the notifier to released.
          (container.read(buildScenarioProvider.notifier)
                  as _FixedScenarioNotifier)
              .release();
          await tester.pump();

          // After release: controller must have called forward() → ticker.
          // RED now: no controller in stub → count stays 0.
          expect(tester.binding.transientCallbackCount, greaterThan(0));

          // Settle past the 250ms crossfade.
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('RELEASE'), findsOneWidget);
          expect(find.textContaining('DEBUG'), findsNothing);
          expect(tester.binding.transientCallbackCount, equals(0));
        },
      );
    });

    // -------------------------------------------------------------------------
    group('320px → no overflow, both phases', () {
      // REGRESSION GUARD: ReleaseTag must not overflow at narrow widths.
      // Likely passes now; keep as regression guard.
      testWidgets(
        '320px width, planning phase → no overflow',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 800));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          final container = ProviderContainer(
            overrides: [
              effectsStoreProvider.overrideWithValue(
                const _FakeEffectsStore(stored: EffectsMode.lite),
              ),
              buildScenarioProvider.overrideWith(
                () => _FixedScenarioNotifier(
                  const BuildScenarioState.initial(),
                ),
              ),
            ],
          );
          addTearDown(container.dispose);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const MaterialApp(
                debugShowCheckedModeBanner: false,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: MediaQuery(
                  data: MediaQueryData(size: Size(320, 800)),
                  child: Scaffold(body: ReleaseTag()),
                ),
              ),
            ),
          );
          await tester.pump();

          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        '320px width, released phase → no overflow',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 800));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          final container = ProviderContainer(
            overrides: [
              effectsStoreProvider.overrideWithValue(
                const _FakeEffectsStore(stored: EffectsMode.lite),
              ),
              buildScenarioProvider.overrideWith(
                () => _FixedScenarioNotifier(
                  const BuildScenarioState.released(),
                ),
              ),
            ],
          );
          addTearDown(container.dispose);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const MaterialApp(
                debugShowCheckedModeBanner: false,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: MediaQuery(
                  data: MediaQueryData(size: Size(320, 800)),
                  child: Scaffold(body: ReleaseTag()),
                ),
              ),
            ),
          );
          await tester.pump();

          expect(tester.takeException(), isNull);
        },
      );
    });
  });
}
