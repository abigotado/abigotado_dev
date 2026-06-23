import 'package:abigotado_dev/src/app/state/scroll_spy_notifier.dart';
import 'package:abigotado_dev/src/app/theme/app_theme.dart';
import 'package:abigotado_dev/src/app/widget/editor_file.dart';
import 'package:abigotado_dev/src/app/widget/reveal_on_scroll.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/core/effects/effects_store.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake — copied from living_background_test.dart (same pattern, same name).
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
// Helper: pump RevealOnScroll in isolation.
//
// [revealedOverride] controls the value of sectionRevealedProvider(metrics)
// injected into the scope. [storedMode] controls effectsModeOf resolution.
// ---------------------------------------------------------------------------

Future<ProviderContainer> _pumpReveal(
  WidgetTester tester, {
  required bool revealedOverride,
  required EffectsMode? storedMode,
  required Widget child,
  Size surfaceSize = const Size(1280, 800),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final container = ProviderContainer(
    overrides: [
      effectsStoreProvider.overrideWithValue(
        _FakeEffectsStore(stored: storedMode),
      ),
      sectionRevealedProvider(EditorFile.metrics).overrideWithValue(
        revealedOverride,
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
        home: Scaffold(
          body: RevealOnScroll(
            file: EditorFile.metrics,
            child: child,
          ),
        ),
      ),
    ),
  );

  return container;
}

// ---------------------------------------------------------------------------
// Helper: read the outermost AnimatedOpacity nested inside RevealOnScroll.
// RevealOnScroll wraps AnimatedSlide > AnimatedOpacity.
// ---------------------------------------------------------------------------

AnimatedOpacity _animatedOpacity(WidgetTester tester) =>
    tester.widget<AnimatedOpacity>(
      find.descendant(
        of: find.byType(RevealOnScroll),
        matching: find.byType(AnimatedOpacity),
      ),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('RevealOnScroll', () {
    // -------------------------------------------------------------------------
    // GREEN guards — RevealOnScroll is real; these assert the wiring.
    // They must stay green through all passes.
    // -------------------------------------------------------------------------

    group('full mode opacity', () {
      testWidgets(
        'full + not revealed → opacity 0',
        (tester) async {
          // sectionRevealedProvider(metrics) = false, full mode.
          // RevealOnScroll.build: revealed = false || false = false
          // → AnimatedOpacity.opacity = 0.
          // GREEN guard (RevealOnScroll is real).
          await _pumpReveal(
            tester,
            revealedOverride: false,
            storedMode: EffectsMode.full,
            child: const SizedBox(width: 100, height: 100),
          );

          expect(
            _animatedOpacity(tester).opacity,
            equals(0.0),
            reason:
                'full mode with sectionRevealed=false must render '
                'AnimatedOpacity with target opacity 0',
          );
        },
      );

      testWidgets(
        'full + revealed → opacity 1',
        (tester) async {
          // sectionRevealedProvider(metrics) = true.
          // revealed = false || true = true → opacity 1.
          // GREEN guard.
          await _pumpReveal(
            tester,
            revealedOverride: true,
            storedMode: EffectsMode.full,
            child: const SizedBox(width: 100, height: 100),
          );

          expect(
            _animatedOpacity(tester).opacity,
            equals(1.0),
            reason:
                'full mode with sectionRevealed=true must render '
                'AnimatedOpacity with target opacity 1',
          );
        },
      );
    });

    group('lite mode', () {
      testWidgets(
        'lite → opacity 1 + Duration.zero even when sectionRevealed is false',
        (tester) async {
          // Lite mode: revealed = (mode == lite) OR ... = true regardless.
          // duration collapses to Duration.zero.
          // GREEN guard.
          await _pumpReveal(
            tester,
            revealedOverride: false,
            storedMode: EffectsMode.lite,
            child: const SizedBox(width: 100, height: 100),
          );

          await tester.pumpAndSettle();

          expect(
            _animatedOpacity(tester).opacity,
            equals(1.0),
            reason:
                'lite mode must force opacity 1 regardless of sectionRevealed',
          );
          expect(
            _animatedOpacity(tester).duration,
            equals(Duration.zero),
            reason:
                'lite mode must collapse AnimatedOpacity duration to zero '
                '(no animation tickers)',
          );
          expect(
            tester.binding.transientCallbackCount,
            equals(0),
            reason:
                'lite mode: Duration.zero must leave no transient animation '
                'callbacks running',
          );
        },
      );
    });

    group('a11y', () {
      testWidgets(
        'a11y: semantics node reachable while not revealed (opacity 0)',
        (tester) async {
          // AnimatedOpacity is used for the fade, NOT Offstage/Visibility/
          // ExcludeSemantics. The child must remain in the semantics tree
          // even at opacity 0.
          //
          // Flutter 3.44 footgun: dispose ensureSemantics handle in-body,
          // not via addTearDown.
          //
          // CONTRACT BUG (RED): AnimatedOpacity(opacity:0) with
          // alwaysIncludeSemantics:false (the default) excludes its subtree
          // from the semantics tree in Flutter 3.44. The green pass must add
          // alwaysIncludeSemantics:true to RevealOnScroll's AnimatedOpacity so
          // the child is visible to assistive tech at opacity 0.
          final handle = tester.ensureSemantics();

          await _pumpReveal(
            tester,
            revealedOverride: false,
            storedMode: EffectsMode.full,
            child: const Text('reveal-probe'),
          );

          // Text widgets always expose their content as a semantics label.
          // find.bySemanticsLabel searches the live semantics tree; the node
          // must be present at opacity 0 because AnimatedOpacity does not
          // exclude semantics (unlike Offstage or ExcludeSemantics).
          expect(
            find.bySemanticsLabel('reveal-probe'),
            findsOneWidget,
            reason:
                'the child must be reachable in the semantics tree even at '
                'opacity 0 — RevealOnScroll uses AnimatedOpacity, not '
                'Offstage/Visibility/ExcludeSemantics',
          );

          handle.dispose();
        },
      );
    });

    group('hit-testing', () {
      testWidgets(
        'full + not revealed → invisible interactive child cannot be tapped',
        (tester) async {
          // opacity 0 still hit-tests, so without IgnorePointer an unrevealed
          // section in the lower viewport would let an invisible CTA intercept
          // taps. IgnorePointer(ignoring: !revealed) blocks that.
          var tapped = false;
          await _pumpReveal(
            tester,
            revealedOverride: false,
            storedMode: EffectsMode.full,
            child: Center(
              child: ElevatedButton(
                onPressed: () => tapped = true,
                child: const Text('cta'),
              ),
            ),
          );

          await tester.tap(
            find.byType(ElevatedButton),
            warnIfMissed: false,
          );
          await tester.pump();

          expect(
            tapped,
            isFalse,
            reason:
                'an unrevealed (opacity 0) interactive child must not receive '
                'taps — IgnorePointer gates pointer input while hidden',
          );
        },
      );

      testWidgets(
        'full + revealed → interactive child is tappable',
        (tester) async {
          var tapped = false;
          await _pumpReveal(
            tester,
            revealedOverride: true,
            storedMode: EffectsMode.full,
            child: Center(
              child: ElevatedButton(
                onPressed: () => tapped = true,
                child: const Text('cta'),
              ),
            ),
          );

          await tester.tap(find.byType(ElevatedButton));
          await tester.pump();

          expect(
            tapped,
            isTrue,
            reason: 'a revealed interactive child must receive taps normally',
          );
        },
      );
    });
  });
}
