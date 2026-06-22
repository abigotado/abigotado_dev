import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/app/theme/app_theme.dart';
import 'package:abigotado_dev/src/app/widget/background/living_background.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/core/effects/effects_store.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// An [EffectsStore] that always returns the same stored mode.
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
// Helper: pump LivingBackground in isolation.
//
// LivingBackground is pumped ALONE inside a SizedBox.expand so the only
// possible ticker is the backdrop's own AnimationController.
// transientCallbackCount is therefore a genuine signal (not polluted by
// TerminalHero or any other widget's controller).
// ---------------------------------------------------------------------------

Future<ProviderContainer> _pumpBackground(
  WidgetTester tester, {
  required EffectsMode? storedMode,
  Size surfaceSize = const Size(1280, 800),
  bool disableAnimations = false,
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
        theme: AppTheme.dark(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: surfaceSize,
            disableAnimations: disableAnimations,
          ),
          child: const Scaffold(
            body: SizedBox.expand(
              child: LivingBackground(key: Key('bg')),
            ),
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
  group('LivingBackgroundPainter', () {
    group('shouldRepaint', () {
      test('t change → repaints', () {
        // STUB returns false unconditionally → RED until green pass implements
        // old.t != t → true.
        const oldPainter = LivingBackgroundPainter(
          t: 0,
          spacing: 48,
          color: AppColors.accentTeal,
          seed: 0,
        );
        const newPainter = LivingBackgroundPainter(
          t: 0.1,
          spacing: 48,
          color: AppColors.accentTeal,
          seed: 0,
        );
        expect(newPainter.shouldRepaint(oldPainter), isTrue);
      });

      test('identical fields → no repaint', () {
        // GREEN guard — stub also returns false for identical fields.
        const painter = LivingBackgroundPainter(
          t: 0,
          spacing: 48,
          color: AppColors.accentTeal,
          seed: 0,
        );
        expect(painter.shouldRepaint(painter), isFalse);
      });

      test('spacing change → repaints', () {
        // RED until green pass compares all four fields.
        const oldPainter = LivingBackgroundPainter(
          t: 0,
          spacing: 48,
          color: AppColors.accentTeal,
          seed: 0,
        );
        const newPainter = LivingBackgroundPainter(
          t: 0,
          spacing: 32,
          color: AppColors.accentTeal,
          seed: 0,
        );
        expect(newPainter.shouldRepaint(oldPainter), isTrue);
      });

      test('color change → repaints', () {
        // RED until green pass compares all four fields.
        const oldPainter = LivingBackgroundPainter(
          t: 0,
          spacing: 48,
          color: AppColors.accentTeal,
          seed: 0,
        );
        const newPainter = LivingBackgroundPainter(
          t: 0,
          spacing: 48,
          color: AppColors.accentPurple,
          seed: 0,
        );
        expect(newPainter.shouldRepaint(oldPainter), isTrue);
      });

      test('seed change → repaints', () {
        // RED until green pass compares all four fields.
        const oldPainter = LivingBackgroundPainter(
          t: 0,
          spacing: 48,
          color: AppColors.accentTeal,
          seed: 0,
        );
        const newPainter = LivingBackgroundPainter(
          t: 0,
          spacing: 48,
          color: AppColors.accentTeal,
          seed: 1,
        );
        expect(newPainter.shouldRepaint(oldPainter), isTrue);
      });
    });
  });

  group('LivingBackground', () {
    // -------------------------------------------------------------------------
    // GREEN guards — the static stub already satisfies these structural
    // contracts, so they must stay green throughout green pass too.
    // -------------------------------------------------------------------------

    testWidgets('lite → zero tickers, CustomPaint present', (tester) async {
      // Lite mode: stored=lite → effectsModeOf resolves to lite →
      // no controller. The static stub already satisfies this.
      await _pumpBackground(tester, storedMode: EffectsMode.lite);
      await tester.pumpAndSettle();

      expect(
        tester.binding.transientCallbackCount,
        equals(0),
        reason: 'lite mode must leave zero transient callbacks running',
      );

      expect(
        find.descendant(
          of: find.byKey(const Key('bg')),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
        reason: 'CustomPaint must always be present inside LivingBackground',
      );
    });

    testWidgets(
      'decorative → ExcludeSemantics ancestor of CustomPaint',
      (tester) async {
        // GREEN guard — static _Backdrop already wraps in ExcludeSemantics.
        await _pumpBackground(tester, storedMode: EffectsMode.lite);
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(ExcludeSemantics),
            matching: find.byType(CustomPaint),
          ),
          findsOneWidget,
          reason:
              'CustomPaint must be a descendant of ExcludeSemantics '
              '(background is purely decorative)',
        );
      },
    );

    testWidgets('RepaintBoundary parents CustomPaint', (tester) async {
      // GREEN guard — static _Backdrop already wraps in RepaintBoundary.
      await _pumpBackground(tester, storedMode: EffectsMode.lite);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(RepaintBoundary),
          matching: find.byType(CustomPaint),
        ),
        findsWidgets,
        reason: 'CustomPaint must be a descendant of RepaintBoundary',
      );
    });

    // -------------------------------------------------------------------------
    // RED — green pass must wire SingleTickerProviderStateMixin + controller.
    // -------------------------------------------------------------------------

    testWidgets('full → ticker running', (tester) async {
      // full mode (stored=full, wide viewport, no OS reduced-motion) must
      // create a repeating AnimationController post-frame.
      //
      // Pump strategy: two pumps to get past the addPostFrameCallback that
      // creates the controller. Do NOT pumpAndSettle — repeat never settles.
      //
      // RED: stub never creates a controller → transientCallbackCount stays 0.
      await _pumpBackground(tester, storedMode: EffectsMode.full);
      await tester.pump(); // frame 1: post-frame callback fires
      await tester.pump(); // frame 2: controller tick registered

      expect(
        tester.binding.transientCallbackCount,
        greaterThan(0),
        reason:
            'full mode must have a running AnimationController '
            '(transientCallbackCount > 0)',
      );
    });

    testWidgets(
      'toggle full→lite disposes controller (escape hatch)',
      (tester) async {
        // Step 1: start in full mode and confirm a ticker is running.
        // Step 2: switch to lite via effectsProvider.notifier.setMode.
        // Step 3: pump twice more; confirm the ticker is gone.
        //
        // RED: precondition (transientCallbackCount > 0) fails because the stub
        // never creates a controller.
        final container = await _pumpBackground(
          tester,
          storedMode: EffectsMode.full,
        );
        await tester.pump();
        await tester.pump();

        // Precondition: controller must be running (fails RED vs the stub).
        expect(
          tester.binding.transientCallbackCount,
          greaterThan(0),
          reason: 'precondition: ticker must be running before toggle',
        );

        // Toggle to lite.
        await container
            .read(effectsProvider.notifier)
            .setMode(EffectsMode.lite);
        await tester.pump();
        await tester.pump();

        expect(
          tester.binding.transientCallbackCount,
          equals(0),
          reason:
              'after toggling to lite the AnimationController must be '
              'disposed and zero transient callbacks must remain',
        );
      },
    );

    testWidgets(
      'toggle full→lite→full recreates the controller without crashing',
      (tester) async {
        // The bidirectional escape hatch: a SingleTickerProviderStateMixin
        // would throw "multiple tickers were created" on the SECOND full,
        // because _reconcile creates a fresh AnimationController each time.
        // This proves TickerProviderStateMixin tolerates the recreate.
        final container = await _pumpBackground(
          tester,
          storedMode: EffectsMode.full,
        );
        await tester.pump();
        await tester.pump();
        expect(tester.binding.transientCallbackCount, greaterThan(0));

        // → lite: the controller is disposed.
        await container
            .read(effectsProvider.notifier)
            .setMode(EffectsMode.lite);
        await tester.pump();
        await tester.pump();
        expect(tester.binding.transientCallbackCount, equals(0));

        // → full again: the controller is RE-created (the crash path under
        // SingleTickerProviderStateMixin).
        await container
            .read(effectsProvider.notifier)
            .setMode(EffectsMode.full);
        await tester.pump();
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: 'recreating the controller on the second full must not throw',
        );
        expect(
          tester.binding.transientCallbackCount,
          greaterThan(0),
          reason: 'the ticker must run again after toggling back to full',
        );
      },
    );
  });
}
