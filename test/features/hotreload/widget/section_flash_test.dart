import 'package:abigotado_dev/src/app/state/hot_reload_notifier.dart';
import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/core/effects/effects_store.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/features/hotreload/flash_timing.dart';
import 'package:abigotado_dev/src/features/hotreload/widget/section_flash.dart';
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
// Helper: pump SectionFlash in a minimal Material tree.
//
// Returns the ProviderContainer so the caller can read/mutate providers
// (fire a pulse via UncontrolledProviderScope). [storedMode] drives
// effectsModeOf; [surfaceSize] determines viewport-based auto-resolution.
// ---------------------------------------------------------------------------

Future<ProviderContainer> _pumpFlash(
  WidgetTester tester, {
  required EffectsMode? storedMode,
  required Widget child,
  int order = 0,
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
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(size: surfaceSize),
          child: Scaffold(
            body: SectionFlash(order: order, child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return container;
}

// ---------------------------------------------------------------------------
// Helper: fire a pulse through the real HotReloadNotifier on the shared
// container, then pump to let the widget tree react.
// ---------------------------------------------------------------------------

Future<void> _firePulse(
  WidgetTester tester,
  ProviderContainer container,
) async {
  container.read(hotReloadProvider.notifier).pulse();
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('SectionFlash', () {
    // -------------------------------------------------------------------------
    group('lite mode — inert (most important contract)', () {
      testWidgets(
        'lite mode: after pulse + pumpAndSettle, zero transient callbacks '
        '(no timers or animation controllers created)',
        (tester) async {
          // Falsifiable: a lite-mode implementation that accidentally creates
          // an AnimationController would leave transient callbacks running.
          final container = await _pumpFlash(
            tester,
            storedMode: EffectsMode.lite,
            child: const Text('flash-probe'),
          );

          await _firePulse(tester, container);
          await tester.pumpAndSettle();

          expect(
            tester.binding.transientCallbackCount,
            equals(0),
            reason:
                'lite mode must schedule no animation tickers after a pulse '
                '— the "lite = no animation" contract',
          );
        },
      );

      testWidgets(
        'lite mode: after pulse, no AnimatedContainer overlay is present',
        (tester) async {
          // In lite mode the widget must return child unchanged — no overlay
          // layer is painted, so no amber AnimatedContainer exists in the tree.
          //
          // Falsifiable: an implementation that paints the overlay even in lite
          // would fail this find.
          final container = await _pumpFlash(
            tester,
            storedMode: EffectsMode.lite,
            child: const Text('flash-probe'),
          );

          await _firePulse(tester, container);
          await tester.pumpAndSettle();

          // No AnimatedContainer overlay should exist at all in lite mode.
          expect(
            find.descendant(
              of: find.byType(SectionFlash),
              matching: find.byType(AnimatedContainer),
            ),
            findsNothing,
            reason:
                'lite mode must not paint an AnimatedContainer overlay — '
                'child is returned as-is',
          );
        },
      );
    });

    // -------------------------------------------------------------------------
    group('full mode — flash overlay', () {
      testWidgets(
        'full mode: after pulse + stagger delay, an IgnorePointer-wrapped '
        'AnimatedContainer with kFlashAnimMs duration exists',
        (tester) async {
          // order=0 → stagger=Duration.zero so we don't need to pump extra.
          // This test is RED until the green pass wires the overlay logic.
          final container = await _pumpFlash(
            tester,
            storedMode: EffectsMode.full,
            child: const Text('flash-probe'),
          );

          await _firePulse(tester, container);
          // Pump past the zero stagger + at least one frame so the overlay
          // timer fires and setState is called.
          await tester.pump(const Duration(milliseconds: 1));

          // An AnimatedContainer must exist inside a SectionFlash.
          final animatedContainerFinder = find.descendant(
            of: find.byType(SectionFlash),
            matching: find.byType(AnimatedContainer),
          );
          expect(
            animatedContainerFinder,
            findsWidgets,
            reason:
                'full mode must produce an AnimatedContainer flash overlay '
                'after the stagger delay has elapsed',
          );

          final overlay = tester.widget<AnimatedContainer>(
            animatedContainerFinder.first,
          );
          expect(
            overlay.duration,
            equals(const Duration(milliseconds: kFlashAnimMs)),
            reason:
                'the flash AnimatedContainer duration must equal kFlashAnimMs',
          );
        },
      );

      testWidgets(
        'full mode: overlay decoration uses AppColors.accentAmber',
        (tester) async {
          // Assert color identity, NOT a specific mid-animation RGBA — that
          // would be brittle. Checking the color constant is always stable.
          final container = await _pumpFlash(
            tester,
            storedMode: EffectsMode.full,
            child: const Text('flash-probe'),
          );

          await _firePulse(tester, container);
          await tester.pump(const Duration(milliseconds: 1));

          final animatedContainerFinder = find.descendant(
            of: find.byType(SectionFlash),
            matching: find.byType(AnimatedContainer),
          );
          expect(
            animatedContainerFinder,
            findsWidgets,
            reason:
                'overlay AnimatedContainer must exist after pulse in full mode',
          );

          final overlay = tester.widget<AnimatedContainer>(
            animatedContainerFinder.first,
          );
          final decoration = overlay.decoration as BoxDecoration?;
          expect(
            decoration,
            isNotNull,
            reason: 'the overlay AnimatedContainer must have a BoxDecoration',
          );
          // Assert amber RGB channels — withAlpha/withOpacity retains them.
          const amber = AppColors.accentAmber;
          expect(
            decoration!.color?.r,
            closeTo(amber.r, 0.01),
            reason:
                'overlay color red channel must match AppColors.accentAmber '
                '(color identity check, not opacity)',
          );
          expect(
            decoration.color?.g,
            closeTo(amber.g, 0.01),
            reason:
                'overlay color green channel must match AppColors.accentAmber',
          );
          expect(
            decoration.color?.b,
            closeTo(amber.b, 0.01),
            reason:
                'overlay color blue channel must match AppColors.accentAmber',
          );
        },
      );

      testWidgets(
        'full mode: overlay is wrapped in IgnorePointer '
        'so it cannot steal taps',
        (tester) async {
          // The overlay is decorative — it must never intercept taps from
          // the child's interactive elements.
          final container = await _pumpFlash(
            tester,
            storedMode: EffectsMode.full,
            child: const Text('flash-probe'),
          );

          await _firePulse(tester, container);
          await tester.pump(const Duration(milliseconds: 1));

          // IgnorePointer must be an ancestor of the AnimatedContainer.
          final ignorePointerFinder = find.descendant(
            of: find.byType(SectionFlash),
            matching: find.byType(IgnorePointer),
          );
          expect(
            ignorePointerFinder,
            findsWidgets,
            reason:
                'the flash overlay must be wrapped in IgnorePointer so it '
                'cannot steal tap events from the child',
          );
        },
      );

      testWidgets(
        'full mode: after kFlashAnimMs has fully elapsed, overlay clears '
        '(transientCallbackCount back to 0)',
        (tester) async {
          // After the hold elapses the overlay decoration reverts to
          // transparent / the AnimatedContainer returns to a cleared state.
          // We check zero tickers as a proxy for "inert".
          final container = await _pumpFlash(
            tester,
            storedMode: EffectsMode.full,
            child: const Text('flash-probe'),
          );

          await _firePulse(tester, container);
          // Pump well past both the hold (kFlashAnimMs) and the animation
          // so everything settles.
          await tester.pump(const Duration(milliseconds: kFlashAnimMs + 100));
          await tester.pumpAndSettle();

          expect(
            tester.binding.transientCallbackCount,
            equals(0),
            reason:
                'after the flash hold has elapsed, all timers and animation '
                'controllers must be inactive (zero transient callbacks)',
          );
        },
      );
    });

    // -------------------------------------------------------------------------
    group('full mode — staggered wave order', () {
      testWidgets(
        'order 2: overlay stays inactive until the 120ms stagger delay '
        'elapses, then activates',
        (tester) async {
          // Guards the wave-ordering WIRING (that widget.order actually reaches
          // the Timer), not just the pure flashDelayForIndex helper: a constant
          // or wrong order passed to the Timer would flash at the wrong time
          // yet pass every order-0 test.
          final container = await _pumpFlash(
            tester,
            storedMode: EffectsMode.full,
            order: 2,
            child: const Text('flash-probe'),
          );

          container.read(hotReloadProvider.notifier).pulse();
          await tester.pump(); // schedule the stagger Timer

          final overlayFinder = find.descendant(
            of: find.byType(SectionFlash),
            matching: find.byType(AnimatedContainer),
          );

          double overlayAlpha() {
            final decoration =
                tester.widget<AnimatedContainer>(overlayFinder).decoration!
                    as BoxDecoration;
            return decoration.color!.a;
          }

          // Before the 120ms stagger (order 2 × 60ms): overlay target is clear.
          await tester.pump(const Duration(milliseconds: 100));
          expect(
            overlayAlpha(),
            lessThan(0.001),
            reason:
                'order-2 section must NOT flash before its 120ms stagger '
                'delay — the overlay target alpha is still 0',
          );

          // After the 120ms stagger: overlay target is the amber peak.
          await tester.pump(const Duration(milliseconds: 40)); // total 140ms
          expect(
            overlayAlpha(),
            closeTo(kFlashPeakOpacity, 0.001),
            reason:
                'order-2 section must flash once its 120ms stagger delay has '
                'elapsed — the overlay target alpha is kFlashPeakOpacity',
          );
        },
      );
    });

    // -------------------------------------------------------------------------
    group('a11y — overlay is decorative', () {
      testWidgets(
        'child semantics are reachable in full mode after a pulse',
        (tester) async {
          // The overlay must never add a semantics node or block the child's
          // own semantics. IgnorePointer + ExcludeSemantics on the overlay
          // (or simply not having Semantics on it) is the correct approach.
          final handle = tester.ensureSemantics();

          final container = await _pumpFlash(
            tester,
            storedMode: EffectsMode.full,
            child: const Text('flash-probe'),
          );

          await _firePulse(tester, container);
          await tester.pump(const Duration(milliseconds: 1));

          expect(
            find.bySemanticsLabel('flash-probe'),
            findsOneWidget,
            reason:
                "the child's semantics must remain reachable while the "
                'flash overlay is active — the overlay adds no semantics node',
          );

          handle.dispose();
        },
      );

      testWidgets(
        'child semantics are reachable in lite mode (no overlay)',
        (tester) async {
          final handle = tester.ensureSemantics();

          final container = await _pumpFlash(
            tester,
            storedMode: EffectsMode.lite,
            child: const Text('flash-probe'),
          );

          await _firePulse(tester, container);
          await tester.pumpAndSettle();

          expect(
            find.bySemanticsLabel('flash-probe'),
            findsOneWidget,
            reason:
                "the child's semantics must be reachable in lite mode — "
                'no overlay wraps or obscures them',
          );

          handle.dispose();
        },
      );
    });

    // -------------------------------------------------------------------------
    group('dispose mid-flash', () {
      testWidgets(
        'full mode: unmounting during an active flash does not throw '
        '(no pending-timer exception)',
        (tester) async {
          // The State must cancel timers in dispose(). If it does not,
          // Flutter will report "Timer still active after test" or the
          // setState callback will run on a disposed object and throw.
          final container = await _pumpFlash(
            tester,
            storedMode: EffectsMode.full,
            child: const Text('flash-probe'),
          );

          await _firePulse(tester, container);
          // Pump only partway into the flash — do NOT settle.
          await tester.pump(const Duration(milliseconds: 50));

          // Unmount by replacing the tree with an unrelated widget.
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();

          expect(
            tester.takeException(),
            isNull,
            reason:
                'unmounting SectionFlash mid-flash must not throw — '
                'dispose() must cancel all pending timers',
          );
        },
      );
    });

    // -------------------------------------------------------------------------
    group('full→lite mode flip mid-flash', () {
      testWidgets(
        'switching from full to lite during an active flash cancels animation '
        '(zero tickers after the switch)',
        (tester) async {
          // Start in full mode and fire a pulse.
          final container = await _pumpFlash(
            tester,
            storedMode: EffectsMode.full,
            child: const Text('flash-probe'),
          );

          await _firePulse(tester, container);
          await tester.pump(const Duration(milliseconds: 50));

          // Switch to lite by updating the effects notifier.
          await container
              .read(effectsProvider.notifier)
              .setMode(EffectsMode.lite);
          await tester.pump();
          await tester.pumpAndSettle();

          expect(
            tester.binding.transientCallbackCount,
            equals(0),
            reason:
                'after flipping to lite mid-flash, all animation tickers '
                'must stop — the "lite = no animation" invariant must hold '
                'even for a mid-flight transition',
          );
        },
      );
    });
  });
}
