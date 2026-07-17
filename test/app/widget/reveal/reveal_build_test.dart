import 'package:abigotado_dev/src/app/state/scroll_spy_notifier.dart';
import 'package:abigotado_dev/src/app/theme/app_theme.dart';
import 'package:abigotado_dev/src/app/widget/editor_file.dart';
import 'package:abigotado_dev/src/app/widget/reveal/reveal_build.dart';
import 'package:abigotado_dev/src/app/widget/reveal/section_build_scope.dart';
import 'package:abigotado_dev/src/app/widget/reveal/section_build_timing.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/core/effects/effects_store.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Harness mirrors reveal_on_scroll_test.dart: a ProviderContainer with a fake
// EffectsStore, UncontrolledProviderScope + MaterialApp, and latch edges
// driven directly through `scrollSpyProvider.notifier.revealSections` (the
// real, already-green notifier — see scroll_spy_notifier_test.dart) rather
// than overriding sectionRevealedProvider with a fixed value, because several
// scenarios below need to observe the actual false→true / true→false EDGE,
// not just a static end value.
//
// RevealBuild is a ConsumerStatefulWidget whose CONTRACTS-pass body is an
// identity passthrough (`return widget.child;` — no Opacity, no
// IgnorePointer, no SectionBuildScope, in every mode). Every test that
// depends on that machinery is RED; the two `[BORN-GREEN]`-tagged tests
// assert only what is ALREADY true of the passthrough AND will remain true
// once the "Intended GREEN render" (see reveal_build.dart's class doc) is
// implemented, so they must stay green through both passes.
//
// CONTRACT BUG (flagged, not papered over): the class doc's own "Intended
// GREEN render" sketch wraps the chrome fade in a bare
// `Opacity(opacity: chromeOpacity(t), ...)` with no `alwaysIncludeSemantics:
// true`. Per Flutter's RenderOpacity ("If false, semantics are excluded when
// opacity is 0.0. Defaults to false.") that sketch would silently drop the
// section's semantics from the tree at opacity 0 — exactly the same footgun
// `RevealOnScroll` already hit and fixed (see reveal_on_scroll.dart's a11y
// doc and reveal_on_scroll_test.dart's own "CONTRACT BUG (RED)" note). The
// "full, newly-measured unrevealed" test below asserts the CORRECT behavior
// (semantics reachable at opacity 0) per this project's established a11y
// contract, not the sketch's literal omission — the green pass must add
// `alwaysIncludeSemantics: true` to that Opacity or this test stays red.
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

/// Fixed-size probe: an explicit [Semantics] label plus a tappable counter
/// button, so a single child can stand in for both the a11y and the
/// hit-testing assertions every scenario below needs.
class _ProbeChild extends StatelessWidget {
  const _ProbeChild({required this.tapCount});

  final ValueNotifier<int> tapCount;

  static const String label = 'reveal-build-probe';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 80,
      child: Semantics(
        label: label,
        child: Center(
          child: ElevatedButton(
            onPressed: () => tapCount.value++,
            child: const Text('tap'),
          ),
        ),
      ),
    );
  }
}

Future<ProviderContainer> _pumpBuild(
  WidgetTester tester, {
  required EffectsMode? storedMode,
  required Widget child,
  EditorFile file = EditorFile.metrics,
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
        theme: AppTheme.dark(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RevealBuild(file: file, child: child),
        ),
      ),
    ),
  );

  return container;
}

Opacity _rootOpacity(WidgetTester tester) => tester.widget<Opacity>(
  find.descendant(
    of: find.byType(RevealBuild),
    matching: find.byType(Opacity),
  ),
);

IgnorePointer _rootIgnorePointer(WidgetTester tester) =>
    tester.widget<IgnorePointer>(
      find.descendant(
        of: find.byType(RevealBuild),
        matching: find.byType(IgnorePointer),
      ),
    );

/// Drives [container]'s scroll-spy state from a fresh boot through a genuine
/// false→true reveal edge for [file], then advances the resulting
/// AnimationController by exactly [elapsedMs] of real build-progress time.
///
/// Skipping straight from the boot default (`sectionRevealedProvider` is
/// `true` while `!hasMeasured`) to `revealSections({file})` would never flip
/// the underlying boolean — it is already `true` — landing on the "already
/// latched: no-op" branch instead of the animated one. So this always routes
/// through an explicit "measured but unrevealed" hard jump first.
Future<void> _pumpToRevealEdge(
  WidgetTester tester,
  ProviderContainer container, {
  required EditorFile file,
  required int elapsedMs,
}) async {
  await tester.pump(); // settle the boot frame.

  container.read(scrollSpyProvider.notifier).revealSections(const {});
  await tester.pump(); // hard jump to unrevealed (synchronous, no ticker).

  container.read(scrollSpyProvider.notifier).revealSections({file});
  await tester.pump(); // build detects the false→true edge and registers
  // the post-frame callback (contract: deferred start, never mid-frame).
  await tester.pump(); // the callback fires here -> forward(from: 0); this
  // is ALSO this ticker's FIRST tick, which anchors its internal start time
  // to THIS frame — so this pump's own requested duration contributes ZERO
  // elapsed animation time (verified empirically against this Flutter
  // version's fake-clock AnimationController/Ticker semantics). Real
  // elapsed-time accumulation begins on the next pump.
  if (elapsedMs > 0) {
    await tester.pump(Duration(milliseconds: elapsedMs));
  }
}

void main() {
  group('RevealBuild', () {
    group('lite mode', () {
      testWidgets(
        // [BORN-GREEN] the passthrough stub already satisfies this in every
        // mode; the "Intended GREEN render" explicitly returns widget.child
        // unchanged for lite too.
        'lite → no SectionBuildScope, zero tickers, child renders and tap '
        'works',
        (tester) async {
          final tapCount = ValueNotifier<int>(0);
          addTearDown(tapCount.dispose);

          await _pumpBuild(
            tester,
            storedMode: EffectsMode.lite,
            child: _ProbeChild(tapCount: tapCount),
          );

          expect(
            find.descendant(
              of: find.byType(RevealBuild),
              matching: find.byType(SectionBuildScope),
            ),
            findsNothing,
            reason: 'lite mode must never provide a SectionBuildScope',
          );
          expect(find.text('tap'), findsOneWidget);
          expect(
            tester.binding.transientCallbackCount,
            equals(0),
            reason: 'lite mode must allocate no ticker',
          );

          await tester.tap(find.byType(ElevatedButton));
          await tester.pump();
          expect(tapCount.value, equals(1));
        },
      );
    });

    group('full — boot (before first measurement)', () {
      testWidgets(
        // [BORN-GREEN] the passthrough stub renders the child unconditionally;
        // the "Intended GREEN render" sets controller.value=1 at boot (no
        // "typing" replay flashing on first paint) — both are fully visible
        // and interactive.
        'full, before first measurement → child is visible and interactive',
        (tester) async {
          final tapCount = ValueNotifier<int>(0);
          addTearDown(tapCount.dispose);

          final container = await _pumpBuild(
            tester,
            storedMode: EffectsMode.full,
            child: _ProbeChild(tapCount: tapCount),
          );
          await tester.pump(); // settle the boot frame; no revealSections
          // call — hasMeasured stays false.

          expect(
            container.read(sectionRevealedProvider(EditorFile.metrics)),
            isTrue,
            reason:
                'precondition: !hasMeasured reports every section '
                'revealed by default',
          );
          expect(find.text('tap'), findsOneWidget);

          await tester.tap(find.byType(ElevatedButton));
          await tester.pump();
          expect(
            tapCount.value,
            equals(1),
            reason:
                'a boot-visible section must already be interactive — '
                'no "un-built" gate before the first measurement',
          );
        },
      );
    });

    group('full — measured unrevealed (hard jump, true → false)', () {
      testWidgets(
        'a single pump hard-jumps to opacity 0, pointer-gated, semantics '
        'still reachable',
        (tester) async {
          final handle = tester.ensureSemantics();
          final tapCount = ValueNotifier<int>(0);
          addTearDown(tapCount.dispose);

          final container = await _pumpBuild(
            tester,
            storedMode: EffectsMode.full,
            child: _ProbeChild(tapCount: tapCount),
          );
          await tester.pump();

          container.read(scrollSpyProvider.notifier).revealSections(const {});
          await tester.pump(); // SINGLE pump — hard jump, no intermediate
          // frame: opacity must already be exactly 0, never a value in
          // (0, 1).

          expect(
            _rootOpacity(tester).opacity,
            equals(0.0),
            reason:
                'a bottom-band section discovered off-screen on first '
                'measurement must hard-jump to hidden, never reverse()',
          );
          expect(_rootIgnorePointer(tester).ignoring, isTrue);
          expect(
            find.bySemanticsLabel(_ProbeChild.label),
            findsOneWidget,
            reason:
                'CONTRACT: the semantics must stay reachable at opacity '
                '0 (mirrors the alwaysIncludeSemantics fix in '
                'RevealOnScroll) — see the file-level CONTRACT BUG note',
          );

          await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
          await tester.pump();
          expect(
            tapCount.value,
            equals(0),
            reason: 'an unrevealed (opacity 0) section must not be tappable',
          );

          handle.dispose();
        },
      );
    });

    group('full — reveal edge (false → true, animates)', () {
      testWidgets(
        'an early mid-chrome frame (~40ms elapsed) shows an opacity '
        'strictly between 0 and 1',
        (tester) async {
          final tapCount = ValueNotifier<int>(0);
          addTearDown(tapCount.dispose);

          final container = await _pumpBuild(
            tester,
            storedMode: EffectsMode.full,
            child: _ProbeChild(tapCount: tapCount),
          );
          await _pumpToRevealEdge(
            tester,
            container,
            file: EditorFile.metrics,
            elapsedMs: 40,
          );

          final opacity = _rootOpacity(tester).opacity;
          expect(
            opacity,
            greaterThan(0.0),
            reason:
                'the build must animate, not hard-jump, on a genuine '
                'false→true reveal',
          );
          expect(opacity, lessThan(1.0));
        },
      );

      testWidgets(
        'a tap mid-build (~300ms elapsed) still registers — pointers stay '
        'live for the whole build',
        (tester) async {
          final tapCount = ValueNotifier<int>(0);
          addTearDown(tapCount.dispose);

          final container = await _pumpBuild(
            tester,
            storedMode: EffectsMode.full,
            child: _ProbeChild(tapCount: tapCount),
          );
          await _pumpToRevealEdge(
            tester,
            container,
            file: EditorFile.metrics,
            elapsedMs: 300,
          );

          expect(
            _rootIgnorePointer(tester).ignoring,
            isFalse,
            reason:
                'IgnorePointer gates on !revealed, not on build '
                'completion',
          );

          await tester.tap(find.byType(ElevatedButton));
          await tester.pump();
          expect(tapCount.value, equals(1));
        },
      );

      testWidgets(
        'past kSectionBuildMs, the build settles: opacity 1, zero tickers, '
        'tap works',
        (tester) async {
          final tapCount = ValueNotifier<int>(0);
          addTearDown(tapCount.dispose);

          final container = await _pumpBuild(
            tester,
            storedMode: EffectsMode.full,
            child: _ProbeChild(tapCount: tapCount),
          );
          await _pumpToRevealEdge(
            tester,
            container,
            file: EditorFile.metrics,
            elapsedMs: kSectionBuildMs + 200,
          );
          await tester.pumpAndSettle();

          expect(_rootOpacity(tester).opacity, equals(1.0));
          expect(
            tester.binding.transientCallbackCount,
            equals(0),
            reason: 'a completed build must stop scheduling frames',
          );

          await tester.tap(find.byType(ElevatedButton));
          await tester.pump();
          expect(tapCount.value, equals(1));
        },
      );
    });

    group('latch-once', () {
      testWidgets(
        'an unrelated rebuild after settling does not replay the build',
        (tester) async {
          final tapCount = ValueNotifier<int>(0);
          addTearDown(tapCount.dispose);

          final container = await _pumpBuild(
            tester,
            storedMode: EffectsMode.full,
            child: _ProbeChild(tapCount: tapCount),
          );
          await _pumpToRevealEdge(
            tester,
            container,
            file: EditorFile.metrics,
            elapsedMs: kSectionBuildMs + 200,
          );
          await tester.pumpAndSettle();
          expect(
            _rootOpacity(tester).opacity,
            equals(1.0),
            reason: 'precondition: the build is already settled',
          );

          // Force an UNRELATED rebuild — a 1px resize, well clear of the
          // compact breakpoint so effectsModeOf's resolved mode does not
          // change. RevealBuild depends on MediaQuery via effectsModeOf, so
          // this alone reruns build() with the SAME (already-true)
          // sectionRevealedProvider value — the no-op branch must hold.
          await tester.binding.setSurfaceSize(const Size(1281, 800));
          await tester.pump();
          await tester.pump();

          expect(
            _rootOpacity(tester).opacity,
            equals(1.0),
            reason: 'a build must never replay once played',
          );
          expect(
            tester.binding.transientCallbackCount,
            equals(0),
            reason: 'an unrelated rebuild must not start a new ticker',
          );
        },
      );
    });

    group('full → lite mid-build (advisor test)', () {
      testWidgets(
        'flipping to lite mid-build tears down the ticker and renders the '
        'static (built) child',
        (tester) async {
          final tapCount = ValueNotifier<int>(0);
          addTearDown(tapCount.dispose);

          final container = await _pumpBuild(
            tester,
            storedMode: EffectsMode.full,
            child: _ProbeChild(tapCount: tapCount),
          );
          await _pumpToRevealEdge(
            tester,
            container,
            file: EditorFile.metrics,
            elapsedMs: 300,
          );
          expect(
            tester.binding.transientCallbackCount,
            greaterThan(0),
            reason: 'precondition: the build is genuinely in flight',
          );

          await container
              .read(effectsProvider.notifier)
              .setMode(
                EffectsMode.lite,
              );
          await tester.pump();
          await tester.pump();

          expect(
            find.descendant(
              of: find.byType(RevealBuild),
              matching: find.byType(Opacity),
            ),
            findsNothing,
            reason:
                'lite renders widget.child directly — no Opacity '
                'wrapper survives the flip',
          );
          expect(find.text('tap'), findsOneWidget);
          expect(
            tester.binding.transientCallbackCount,
            equals(0),
            reason:
                'a full→lite flip mid-build must dispose the '
                'controller — zero tickers',
          );
        },
      );
    });

    group('layout stability', () {
      testWidgets(
        'hidden vs mid-build vs settled → identical probe size (paint-only '
        'wrappers)',
        (tester) async {
          final tapCount = ValueNotifier<int>(0);
          addTearDown(tapCount.dispose);

          final container = await _pumpBuild(
            tester,
            storedMode: EffectsMode.full,
            child: _ProbeChild(tapCount: tapCount),
          );

          // Hidden.
          await tester.pump();
          container.read(scrollSpyProvider.notifier).revealSections(const {});
          await tester.pump();
          expect(
            _rootOpacity(tester).opacity,
            equals(0.0),
            reason: 'precondition: genuinely hidden',
          );
          final hiddenSize = tester.getSize(find.byType(_ProbeChild));

          // Mid-CHROME (40 ms — inside the [0, 88 ms] chrome window, where
          // the root opacity is genuinely intermediate).
          container.read(scrollSpyProvider.notifier).revealSections({
            EditorFile.metrics,
          });
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 40));
          final chromeOpacityMid = _rootOpacity(tester).opacity;
          expect(
            chromeOpacityMid,
            greaterThan(0.0),
            reason: 'precondition: genuinely mid-chrome',
          );
          expect(chromeOpacityMid, lessThan(1.0));
          final midChromeSize = tester.getSize(find.byType(_ProbeChild));

          // Mid-CASCADE (400 ms of 800). The chrome window closed at 88 ms —
          // the root Opacity correctly reads exactly 1.0 here — so the
          // "genuinely mid-build" precondition is pinned via the scope's
          // animation progress instead.
          await tester.pump(const Duration(milliseconds: 360));
          final progress = tester
              .widget<SectionBuildScope>(find.byType(SectionBuildScope))
              .progress
              .value;
          expect(
            progress,
            allOf(greaterThan(0.0), lessThan(1.0)),
            reason: 'precondition: genuinely mid-cascade',
          );
          final midCascadeSize = tester.getSize(find.byType(_ProbeChild));

          // Settled.
          await tester.pump(const Duration(milliseconds: kSectionBuildMs));
          await tester.pumpAndSettle();
          expect(
            _rootOpacity(tester).opacity,
            equals(1.0),
            reason: 'precondition: genuinely settled',
          );
          final settledSize = tester.getSize(find.byType(_ProbeChild));

          expect(
            midChromeSize,
            equals(hiddenSize),
            reason: 'a mid-chrome frame must not resize the probe',
          );
          expect(
            midCascadeSize,
            equals(hiddenSize),
            reason: 'a mid-cascade frame must not resize the probe',
          );
          expect(
            settledSize,
            equals(hiddenSize),
            reason: 'a settled frame must not resize the probe',
          );
        },
      );
    });
  });
}
