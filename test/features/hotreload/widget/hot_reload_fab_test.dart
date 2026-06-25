import 'package:abigotado_dev/src/app/state/hot_reload_notifier.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/core/effects/effects_store.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/features/hotreload/widget/hot_reload_fab.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake effects store — read-only; write/clear are no-ops.
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
// Helper: pump HotReloadFab in a minimal, locale-aware Material tree.
//
// Returns the ProviderContainer so the caller can read provider state after
// the tap. [storedMode] drives effectsModeOf; [surfaceSize] determines
// whether the viewport is considered compact (< 600 px → lite auto).
// ---------------------------------------------------------------------------

Future<ProviderContainer> _pumpFab(
  WidgetTester tester, {
  required EffectsMode? storedMode,
  Size surfaceSize = const Size(1280, 800),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final container = ProviderContainer(
    overrides: [
      effectsStoreProvider.overrideWithValue(
        _FakeEffectsStore(stored: storedMode),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        // Force en so label assertions are locale-independent.
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(size: surfaceSize),
          child: const Scaffold(
            body: Center(child: HotReloadFab()),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return container;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('HotReloadFab', () {
    group('rendering', () {
      testWidgets(
        'renders the ⚡ glyph (exactly one widget carrying the text)',
        (tester) async {
          await _pumpFab(tester, storedMode: EffectsMode.full);

          expect(
            find.text('⚡'),
            findsOneWidget,
            reason:
                'HotReloadFab must display the ⚡ lightning bolt glyph '
                'as its visual affordance',
          );
        },
      );
    });

    group('tap target', () {
      testWidgets(
        'diameter constant is 48 px (≥ 44 px minimum tap target)',
        (tester) async {
          // Assert the exported constant meets the minimum before testing the
          // rendered size — catches a regression in the constant itself.
          expect(
            HotReloadFab.diameter,
            greaterThanOrEqualTo(44),
            reason: 'HotReloadFab.diameter must be ≥ 44 px for tap target',
          );
          expect(
            HotReloadFab.diameter,
            equals(48),
            reason: 'HotReloadFab.diameter must equal 48 px per the contract',
          );
        },
      );

      testWidgets(
        'rendered widget has size ≥ 44 × 44 px',
        (tester) async {
          await _pumpFab(tester, storedMode: EffectsMode.full);

          final size = tester.getSize(find.byType(HotReloadFab));
          expect(
            size.width,
            greaterThanOrEqualTo(44),
            reason:
                'tappable area width must be ≥ 44 px '
                '(HotReloadFab.diameter = ${HotReloadFab.diameter})',
          );
          expect(
            size.height,
            greaterThanOrEqualTo(44),
            reason:
                'tappable area height must be ≥ 44 px '
                '(HotReloadFab.diameter = ${HotReloadFab.diameter})',
          );
        },
      );
    });

    group('tap fires the pulse', () {
      // Falsifiable: catches an unwired onTap (most common wiring omission).
      testWidgets(
        'full mode: tap → hotReloadProvider id increments',
        (tester) async {
          final container = await _pumpFab(
            tester,
            storedMode: EffectsMode.full,
          );

          final before = container.read(hotReloadProvider);
          await tester.tap(find.byType(HotReloadFab));
          await tester.pump();
          final after = container.read(hotReloadProvider);

          expect(
            after,
            greaterThan(before),
            reason:
                'tapping HotReloadFab must call pulse() and increase the '
                'hotReloadProvider id',
          );
        },
      );

      testWidgets(
        'lite mode: tap → hotReloadProvider id increments '
        '(FAB is chrome — not gated by lite)',
        (tester) async {
          final container = await _pumpFab(
            tester,
            storedMode: EffectsMode.lite,
          );

          final before = container.read(hotReloadProvider);
          await tester.tap(find.byType(HotReloadFab));
          await tester.pump();
          final after = container.read(hotReloadProvider);

          expect(
            after,
            greaterThan(before),
            reason:
                'HotReloadFab must fire pulse() in lite mode too — '
                'it is app chrome, never gated by effects mode',
          );
        },
      );
    });

    group('a11y', () {
      // Flutter 3.44 footgun (project memory): use isSemantics (not
      // matchesSemantics/containsSemantics) for flag-subset checks; dispose
      // the ensureSemantics handle in the test body, not via addTearDown.

      testWidgets(
        'a Semantics button node carries the localized "Hot reload" label',
        (tester) async {
          final handle = tester.ensureSemantics();

          await _pumpFab(tester, storedMode: EffectsMode.full);

          // The accessible affordance must be findable by its en label.
          expect(
            find.bySemanticsLabel('Hot reload'),
            findsOneWidget,
            reason:
                'HotReloadFab must expose a Semantics button with label '
                '"Hot reload" so screen readers announce it correctly',
          );

          // The Semantics node must have the button flag.
          final node = tester.getSemantics(find.bySemanticsLabel('Hot reload'));
          expect(
            node,
            isSemantics(isButton: true),
            reason:
                'the "Hot reload" semantics node must carry the button flag',
          );

          handle.dispose();
        },
      );

      testWidgets(
        'the ⚡ glyph is NOT separately announced — label excludes ⚡',
        (tester) async {
          final handle = tester.ensureSemantics();

          await _pumpFab(tester, storedMode: EffectsMode.full);

          // The glyph must be wrapped in ExcludeSemantics so the screen reader
          // only hears "Hot reload", not "⚡" followed by "Hot reload".
          expect(
            find.bySemanticsLabel('⚡'),
            findsNothing,
            reason:
                'the ⚡ glyph is decorative — it must not appear as its '
                'own semantics node',
          );

          final node = tester.getSemantics(find.bySemanticsLabel('Hot reload'));
          expect(
            node.label,
            isNot(contains('⚡')),
            reason:
                'the accessible label must not contain ⚡ — '
                'only "Hot reload" must be announced',
          );

          handle.dispose();
        },
      );
    });

    group('both effects modes — FAB renders and fires pulse', () {
      for (final mode in EffectsMode.values) {
        testWidgets(
          '${mode.name} mode: ⚡ renders and tap increments hotReloadProvider',
          (tester) async {
            final container = await _pumpFab(tester, storedMode: mode);

            expect(
              find.text('⚡'),
              findsOneWidget,
              reason: 'HotReloadFab must render ⚡ in ${mode.name} mode',
            );

            final before = container.read(hotReloadProvider);
            await tester.tap(find.byType(HotReloadFab));
            await tester.pump();
            final after = container.read(hotReloadProvider);

            expect(
              after,
              greaterThan(before),
              reason:
                  'tap must fire pulse() in ${mode.name} mode — '
                  'FAB is chrome, never gated by effects mode',
            );
          },
        );
      }
    });
  });
}
