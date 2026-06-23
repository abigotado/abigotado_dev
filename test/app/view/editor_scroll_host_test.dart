import 'package:abigotado_dev/src/app/state/scroll_spy_notifier.dart';
import 'package:abigotado_dev/src/app/theme/app_theme.dart';
import 'package:abigotado_dev/src/app/view/editor_scroll_host.dart';
import 'package:abigotado_dev/src/app/view/scroll_spy_geometry.dart';
import 'package:abigotado_dev/src/app/widget/editor_file.dart';
import 'package:abigotado_dev/src/core/clock/scenario_clock.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/core/effects/effects_store.dart';
import 'package:abigotado_dev/src/core/locale/locale_store.dart';
import 'package:abigotado_dev/src/core/locale/platform_locale_reader.dart';
import 'package:abigotado_dev/src/core/locale/supported_locale.dart';
import 'package:abigotado_dev/src/features/changelog/widget/changelog_section.dart';
import 'package:abigotado_dev/src/features/cta/widget/merge_cta_section.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/features/hero/state/build_scenario_notifier.dart';
import 'package:abigotado_dev/src/features/hero/view/terminal_hero.dart';
import 'package:abigotado_dev/src/features/locale/state/locale_notifier.dart';
import 'package:abigotado_dev/src/features/metrics/widget/metrics_section.dart';
import 'package:abigotado_dev/src/features/pubspec/widget/pubspec_section.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

// Lite store — all animations disabled, pumpAndSettle safe.
final class _LiteEffectsStore implements EffectsStore {
  const _LiteEffectsStore();

  @override
  EffectsMode? read() => EffectsMode.lite;

  @override
  Future<void> write(EffectsMode mode) async {}

  @override
  Future<void> clear() async {}
}

// Full store — manual choice absent. At 1280×800 desktop width with no
// OS reduced-motion, effectsModeOf resolves to full. Used ONLY for the
// FIX-3 asymmetry test where we never call pumpAndSettle after pump setup.
final class _FullEffectsStore implements EffectsStore {
  const _FullEffectsStore();

  @override
  EffectsMode? read() => null;

  @override
  Future<void> write(EffectsMode mode) async {}

  @override
  Future<void> clear() async {}
}

final class _FakeLocaleStore implements LocaleStore {
  const _FakeLocaleStore();

  @override
  SupportedLocale? read() => null;

  @override
  Future<void> write(SupportedLocale locale) async {}

  @override
  Future<void> clear() async {}
}

final class _FakePlatformLocaleReader implements PlatformLocaleReader {
  const _FakePlatformLocaleReader();

  @override
  List<Locale> get locales => const [];

  @override
  String? get timeZoneId => null;
}

// Fake scenario clock: resolves all elapse() calls immediately so that
// TerminalHero's clock-driven transitions complete without real delays.
final class _InstantClock implements ScenarioClock {
  @override
  Future<void> elapse(Duration duration) => Future<void>.value();
}

// ---------------------------------------------------------------------------
// Finder for the main (vertical) scroll view owned by EditorScrollHost.
//
// LandingPage → PubspecCard adds a horizontal SingleChildScrollView, so we
// must target only the vertical one inside EditorScrollHost.
// ---------------------------------------------------------------------------

final Finder _verticalScrollView = find.byWidgetPredicate(
  (w) => w is SingleChildScrollView && w.scrollDirection == Axis.vertical,
);

// ---------------------------------------------------------------------------
// Helper: pump EditorScrollHost in a full provider scope + Material tree.
//
// Returns the ProviderContainer so callers can drive the notifier directly.
// ---------------------------------------------------------------------------

Future<ProviderContainer> _pumpHost(
  WidgetTester tester, {
  EffectsStore effectsStore = const _LiteEffectsStore(),
  Size surfaceSize = const Size(1280, 800),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final container = ProviderContainer(
    overrides: [
      localeStoreProvider.overrideWithValue(const _FakeLocaleStore()),
      platformReaderProvider.overrideWithValue(
        const _FakePlatformLocaleReader(),
      ),
      effectsStoreProvider.overrideWithValue(effectsStore),
      scenarioClockProvider.overrideWithValue(_InstantClock()),
    ],
  );
  addTearDown(container.dispose);

  // Wrap MaterialApp in a Consumer so that changes to localeProvider rebuild
  // MaterialApp with the new locale, mirroring how AbigotadoApp works. Without
  // this, calling setLocale() changes the provider state but never causes a
  // widget-tree reflow — the locale-reflow tests would be vacuous.
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) {
          final locale = ref.watch(localeProvider.select((s) => s.locale));
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: locale,
            home: const Scaffold(body: EditorScrollHost()),
          );
        },
      ),
    ),
  );

  return container;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('EditorScrollHost', () {
    // -------------------------------------------------------------------------
    group('scroll-spy active file', () {
      testWidgets(
        'at rest the active file is fileHero',
        (tester) async {
          final container = await _pumpHost(tester);
          // lite mode: pumpAndSettle is safe (no persistent tickers).
          await tester.pumpAndSettle();

          // Default state; _onScroll is an empty stub so no update happens,
          // but the initial state is fileHero. Baseline anchor: its value
          // becomes interesting only when the companion tests scroll it.
          expect(
            container.read(scrollSpyProvider).activeFile,
            equals(EditorFile.fileHero),
          );
        },
      );

      testWidgets(
        'scrolling to the bottom activates contacts (bottom-pin)',
        (tester) async {
          final container = await _pumpHost(tester);
          await tester.pumpAndSettle();

          // Drag a large distance downward to reach maxScrollExtent.
          await tester.drag(_verticalScrollView, const Offset(0, -10000));
          await tester.pumpAndSettle();

          // RED: _onScroll is an empty stub so activeFile never updates.
          // Green pass implements _onScroll → becomes contacts via bottom-pin.
          expect(
            container.read(scrollSpyProvider).activeFile,
            equals(EditorFile.contacts),
          );
        },
      );

      testWidgets(
        'scrolling part-way advances the active file past fileHero',
        (tester) async {
          final container = await _pumpHost(tester);
          await tester.pumpAndSettle();

          // Drag a moderate distance — enough to cross at least one section
          // boundary. We only assert the wiring is connected (active file
          // advances), not a specific file. Pure-function tests own thresholds.
          await tester.drag(_verticalScrollView, const Offset(0, -600));
          await tester.pumpAndSettle();

          // RED: _onScroll is an empty stub → stays fileHero.
          // Green pass: active file must advance past the first section.
          expect(
            container.read(scrollSpyProvider).activeFile,
            isNot(equals(EditorFile.fileHero)),
          );
        },
      );
    });

    // -------------------------------------------------------------------------
    group('tap-to-scroll', () {
      testWidgets(
        'requesting a scroll to contacts brings MergeCtaSection into view',
        (tester) async {
          final container = await _pumpHost(tester);
          await tester.pumpAndSettle();

          // Dispatch a scroll request directly via the notifier.
          // RED: requestScrollTo throws UnimplementedError in the stub.
          container
              .read(scrollSpyProvider.notifier)
              .requestScrollTo(EditorFile.contacts);
          await tester.pumpAndSettle();

          // MergeCtaSection is the contacts section. After the scroll it must
          // be within the 800 px viewport.
          final ctaTopLeft = tester.getTopLeft(find.byType(MergeCtaSection));
          expect(
            ctaTopLeft.dy,
            lessThan(800),
            reason: 'MergeCtaSection must be scrolled into the 800 px viewport',
          );

          expect(
            container.read(scrollSpyProvider).activeFile,
            equals(EditorFile.contacts),
          );
        },
      );
    });

    // -------------------------------------------------------------------------
    group('lite vs full animation (FIX-3 asymmetry)', () {
      // In FULL mode Scrollable.ensureVisible is called with duration=320ms,
      // so after a single pump() the scroll animation has just started and
      // MergeCtaSection is still off-screen. After pump(400ms) the animation
      // has completed and MergeCtaSection is within the 800px viewport.
      //
      // In LITE mode duration=Duration.zero, so ensureVisible calls jumpTo
      // internally — MergeCtaSection is in the viewport after one pump().
      //
      // This asymmetry is caused solely by the duration branch in
      // _onScrollRequest and is falsifiable: removing the lite branch (making
      // lite also use 320ms) makes the lite assertion fail; removing the full
      // branch (making full also use Duration.zero) makes the full assertion
      // fail.
      //
      // Hero-ticker caveat: _FullEffectsStore returns null (no manual choice),
      // so at 1280px wide effectsModeOf resolves to full. TerminalHero creates
      // spinner+cursor AnimationControllers that repeat() forever — never call
      // pumpAndSettle in full mode. We use _InstantClock (already injected by
      // _pumpHost) so the build scenario completes via microtasks; the spinner/
      // cursor controllers remain active but cause no pending-timer errors
      // (they are frame-callback-based, not Dart Timers, and are disposed with
      // the widget tree).
      testWidgets(
        'full mode: contacts NOT in viewport after one pump, '
        'IS in viewport after 400 ms',
        (tester) async {
          final container = await _pumpHost(
            tester,
            effectsStore: const _FullEffectsStore(),
          );
          // One pump settles layout; do NOT pumpAndSettle (spinner repeats).
          await tester.pump();

          container
              .read(scrollSpyProvider.notifier)
              .requestScrollTo(EditorFile.contacts);
          // One frame tick — the 320 ms animation has just been scheduled;
          // essentially 0 ms has elapsed, MergeCtaSection still off-screen.
          await tester.pump();

          final topAfterOnePump = tester
              .getTopLeft(find.byType(MergeCtaSection))
              .dy;
          expect(
            topAfterOnePump,
            greaterThanOrEqualTo(800),
            reason:
                'MergeCtaSection must still be off-screen (dy >= 800) after '
                'the first frame of a 320 ms animated scroll.',
          );

          // Advance past the animation duration.
          await tester.pump(const Duration(milliseconds: 400));

          final topAfterAnimation = tester
              .getTopLeft(find.byType(MergeCtaSection))
              .dy;
          expect(
            topAfterAnimation,
            lessThan(800),
            reason:
                'MergeCtaSection must be within the 800 px viewport after '
                'the 320 ms scroll animation completes.',
          );
        },
      );

      testWidgets(
        'lite mode: contacts IS in viewport after one pump (instant jump)',
        (tester) async {
          final container = await _pumpHost(tester); // _LiteEffectsStore
          await tester.pumpAndSettle();

          container
              .read(scrollSpyProvider.notifier)
              .requestScrollTo(EditorFile.contacts);
          // A single pump suffices: Duration.zero makes ensureVisible call
          // jumpTo internally — immediate scroll, no animation ticker.
          await tester.pump();

          final top = tester.getTopLeft(find.byType(MergeCtaSection)).dy;
          expect(
            top,
            lessThan(800),
            reason:
                'In lite mode the jump is instant — MergeCtaSection must be '
                'within the 800 px viewport after a single pump().',
          );

          // Verify the instant jump left no animation ticker pending.
          expect(
            tester.binding.transientCallbackCount,
            equals(0),
            reason: 'Lite mode uses jumpTo — no animation ticker must be left.',
          );
        },
      );
    });

    // -------------------------------------------------------------------------
    group('stationary reflow re-derive (FIX-4)', () {
      // Proves that NotificationListener<ScrollMetricsNotification> triggers a
      // correct re-derive when layout changes without a scroll event.
      //
      // Mechanism: EditorScrollHost wraps its SingleChildScrollView in a
      // NotificationListener<ScrollMetricsNotification>. Any change to
      // viewport or content dimensions fires this notification even when the
      // scroll offset is stationary — the handler calls _scheduleUpdate(),
      // which posts _updateActive() for the next frame.
      //
      // Falsifiability: the scroll is positioned at
      //   metricsOffset - kActivationLine + 5 px
      // so metrics is active by the narrowest margin. Resizing from 1280 px
      // to 600 px forces prose to wrap on a narrower 552 px text area; the
      // hero section grows taller, pushing metricsOffset up by more than
      // 5 px. At the same scroll position, metrics is no longer active —
      // the independent live computation returns fileHero (or another
      // section). If the NotificationListener is removed, the notifier
      // retains the pre-resize value (metrics) and the assertion fails.
      //
      // Harness note: _pumpHost's MaterialApp now carries
      //   locale: ref.watch(localeProvider).locale
      // mirroring AbigotadoApp. Without that fix a locale switch never
      // causes a widget-tree rebuild, making locale-based reflow tests
      // vacuous. The resize variant here is unambiguously deterministic.
      testWidgets(
        'notifier matches live geometry after a stationary viewport resize',
        (tester) async {
          // 1. Initial layout at 1280x800 (desktop, lite mode).
          final container = await _pumpHost(tester); // 1280x800, lite
          await tester.pumpAndSettle();

          // 2. Measure the metrics section top offset at scroll = 0.
          // RenderAbstractViewport.of(ro).getOffsetToReveal(ro, 0) returns
          // the scroll offset at which the section's top edge aligns with
          // the viewport top — identical to the value _updateActive uses.
          final metricsRO = tester.renderObject(find.byType(MetricsSection));
          final scrollViewport = RenderAbstractViewport.of(metricsRO);
          final metricsOffset = scrollViewport
              .getOffsetToReveal(metricsRO, 0)
              .offset;

          // Guard: metrics section must sit below the hero (positive offset).
          expect(
            metricsOffset,
            greaterThan(0),
            reason: 'metricsOffset must be positive — hero has height.',
          );

          // 3. Jump to just past the metrics activation boundary so that
          // metrics is the active file by the narrowest margin (5 px).
          final targetScrollOffset = metricsOffset - kActivationLine + 5.0;
          final vertScrollableFinder = find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          );
          // Cascade: store the position reference and call jumpTo atomically
          // to satisfy cascade_invocations; later reads use the same ref.
          final scrollPos =
              tester.state<ScrollableState>(vertScrollableFinder.first).position
                ..jumpTo(targetScrollOffset);
          await tester.pumpAndSettle();

          // 4. Precondition: metrics must be active before the resize.
          expect(
            container.read(scrollSpyProvider).activeFile,
            equals(EditorFile.metrics),
            reason:
                'Precondition: 5 px past metrics activation threshold '
                '— metrics must be active before the resize.',
          );

          // 5. Resize to 600 px wide. At 600 px the 1000 px ContentWidth
          // cap no longer applies; sections grow taller as text wraps on
          // a narrower 552 px area. setSurfaceSize triggers a layout pass:
          //   ScrollMetricsNotification fires (microtask, post-layout)
          //     → NotificationListener calls _updateActive() DIRECTLY
          //       → activeFile re-derives in the same microtask.
          // A SINGLE pump is deliberate: the layout pass runs, then the
          // microtask flushes within this pump and _updateActive executes
          // synchronously. No second frame is pumped — so this test fails if
          // the re-derive is deferred to a frame that an idle app never
          // schedules (e.g. addPostFrameCallback without scheduleFrame).
          await tester.binding.setSurfaceSize(const Size(600, 800));
          await tester.pump();

          // 6. Independent live computation from post-resize geometry.
          // Build the sections list in EditorFile.values order, mirroring
          // _updateActive but reading directly from the live render objects.
          // Section types appear exactly once in the tree so find.byType
          // is unambiguous.
          final sectionFinders = <EditorFile, Finder>{
            EditorFile.fileHero: find.byType(TerminalHero),
            EditorFile.metrics: find.byType(MetricsSection),
            EditorFile.pubspec: find.byType(PubspecSection),
            EditorFile.changelog: find.byType(ChangelogSection),
            EditorFile.contacts: find.byType(MergeCtaSection),
          };

          final liveSections = <({EditorFile file, double offset})>[];
          for (final file in EditorFile.values) {
            final ro = tester.renderObject(sectionFinders[file]!);
            if (!ro.attached) continue;
            final offset = RenderAbstractViewport.of(
              ro,
            ).getOffsetToReveal(ro, 0).offset;
            liveSections.add((file: file, offset: offset));
          }

          // Scroll position is unchanged (no one moved it after the resize).
          final expectedActiveFile = activeEditorFile(
            sections: liveSections,
            scrollOffset: scrollPos.pixels,
            maxScrollExtent: scrollPos.maxScrollExtent,
          );

          // 7. Assert notifier == live independent computation.
          // If NotificationListener<ScrollMetricsNotification> is intact,
          // _updateActive() ran post-resize and the notifier agrees with
          // the live computation. If the NotificationListener is removed,
          // the notifier holds the stale pre-resize value (metrics) while
          // the live computation returns a different file (because the
          // metricsOffset shifted). The assertion catches that divergence.
          expect(
            container.read(scrollSpyProvider).activeFile,
            equals(expectedActiveFile),
            reason:
                'After a stationary resize the notifier must re-derive '
                'activeFile via NotificationListener; expected '
                '$expectedActiveFile.',
          );

          expect(tester.takeException(), isNull);
        },
      );
    });

    // -------------------------------------------------------------------------
    group('scroll-reveal wiring', () {
      // Falsifiability:
      //
      // 'full: drag → revealed contains below-fold file' is RED because
      // EditorScrollHost._updateActive does NOT call revealSections yet
      // (green pass wires it). So scrollSpyProvider.revealed stays {} and
      // hasMeasured stays false, failing the assertions.
      //
      // 'lite: revealed stays empty' is GREEN — lite mode means the host
      // still won't call revealSections (same missing wiring), but the test
      // asserts the empty/unmeasured state AND that sections are visible via
      // mode==lite OR, which RevealOnScroll already implements.
      //
      // Hero-ticker caveat (full mode): do NOT call pumpAndSettle —
      // TerminalHero's spinner/cursor controllers repeat() forever. Use
      // explicit pump(Duration) only.

      testWidgets(
        'full: drag past a below-fold section → revealed contains it '
        'and hasMeasured is true',
        (tester) async {
          // RED: host does not call revealSections → revealed stays {} and
          // hasMeasured stays false. The assertions on revealed/hasMeasured
          // will fail once the scroll actually happens.
          final container = await _pumpHost(
            tester,
            effectsStore: const _FullEffectsStore(),
          );
          // One pump to settle layout without pumpAndSettle (spinner repeats).
          await tester.pump();

          // Drag down by a large amount to push below-fold sections past the
          // reveal line. Use a direct scroll offset jump for reliability.
          final vertScrollable = find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          );
          tester
              .state<ScrollableState>(vertScrollable.first)
              .position
              .jumpTo(3000);

          // Give the scroll controller listener one frame to fire.
          await tester.pump(const Duration(milliseconds: 500));

          final state = container.read(scrollSpyProvider);

          expect(
            state.hasMeasured,
            isTrue,
            reason:
                'after scrolling the host must have performed at least one '
                'reveal measurement (hasMeasured=true)',
          );
          expect(
            state.revealed,
            contains(EditorFile.contacts),
            reason:
                'scrolling to offset 3000 must have pushed contacts past the '
                'reveal line — revealed must contain it',
          );
        },
      );

      testWidgets(
        'lite: revealed stays empty and hasMeasured false; '
        'sections visible via mode==lite',
        (tester) async {
          // GREEN guard: lite mode → host never calls revealSections (even
          // after green pass, full-mode branch is gated). revealed stays {},
          // hasMeasured stays false. RevealOnScroll shows all sections because
          // mode==lite forces revealed=true regardless of the provider.
          final container = await _pumpHost(
            tester,
          ); // _LiteEffectsStore by default
          await tester.pumpAndSettle();

          final state = container.read(scrollSpyProvider);
          expect(
            state.revealed.isEmpty,
            isTrue,
            reason:
                'lite mode: host must not call revealSections → revealed '
                'stays empty',
          );
          expect(
            state.hasMeasured,
            isFalse,
            reason:
                'lite mode: hasMeasured must remain false (no measurements '
                'taken in lite mode)',
          );

          // Sections must be visible (lite forces opacity=1 in RevealOnScroll).
          expect(find.byType(MetricsSection), findsOneWidget);
          expect(find.byType(MergeCtaSection), findsOneWidget);
        },
      );
    });
  });
}
