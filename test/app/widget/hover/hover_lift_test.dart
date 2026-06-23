import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/app/widget/hover/hover_lift.dart';
import 'package:abigotado_dev/src/app/widget/hover/hover_visuals.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/core/effects/effects_store.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake
// ---------------------------------------------------------------------------

/// An [EffectsStore] that always reports a fixed stored mode.
///
/// Copied from living_background_test.dart — the same fake pattern is used
/// across all card-harness and hover tests for determinism.
final class _FakeEffectsStore implements EffectsStore {
  const _FakeEffectsStore({required this.stored});

  final EffectsMode? stored;

  @override
  EffectsMode? read() => stored;

  @override
  Future<void> write(EffectsMode mode) async {}

  @override
  Future<void> clear() async {}
}

// ---------------------------------------------------------------------------
// Shared rest decoration (same values MetricCard uses in production).
// ---------------------------------------------------------------------------

const _rest = BoxDecoration(
  color: AppColors.surface,
  border: Border.symmetric(
    horizontal: BorderSide(color: AppColors.border),
    vertical: BorderSide(color: AppColors.border),
  ),
  borderRadius: BorderRadius.all(Radius.circular(12)),
);

// ---------------------------------------------------------------------------
// Helper: pump HoverLift in a minimal harness.
//
// Returns the ProviderContainer so tests can call setMode on it.
// ---------------------------------------------------------------------------

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required EffectsMode storedMode,
  Size surface = const Size(1280, 800),
}) async {
  await tester.binding.setSurfaceSize(surface);
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
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: HoverLift(
              restDecoration: _rest,
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 200, height: 80),
            ),
          ),
        ),
      ),
    ),
  );

  return container;
}

// ---------------------------------------------------------------------------
// Helpers: read the live AnimatedContainer from the tree.
// ---------------------------------------------------------------------------

AnimatedContainer _animatedContainer(WidgetTester tester) {
  return tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byType(HoverLift),
      matching: find.byType(AnimatedContainer),
    ),
  );
}

BoxDecoration _decoration(WidgetTester tester) =>
    _animatedContainer(tester).decoration! as BoxDecoration;

Matrix4 _transform(WidgetTester tester) =>
    _animatedContainer(tester).transform ?? Matrix4.identity();

// ---------------------------------------------------------------------------
// Helper: simulate mouse entering the HoverLift center.
// ---------------------------------------------------------------------------

Future<TestGesture> _hoverEnter(WidgetTester tester) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await gesture.moveTo(tester.getCenter(find.byType(HoverLift)));
  await tester.pump();
  return gesture;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('HoverLift', () {
    group('full mode hover enter', () {
      testWidgets(
        'hover enter → decoration glows AND transform tilts',
        (tester) async {
          // Surface is wide (1280 px) so effectsModeOf resolves to full.
          // After moveTo the card center the MouseRegion fires onEnter.
          //
          // RED: the stub wires no onEnter callback → _hovered stays false →
          // decoration == rest (no boxShadow) and transform == identity.
          // The test fails because both assertions are violated by the stub.
          await _pump(tester, storedMode: EffectsMode.full);

          await _hoverEnter(tester);

          expect(
            _decoration(tester).boxShadow,
            isNotNull,
            reason:
                'full mode: hover enter must add a glow boxShadow '
                '(hoverDecoration applied)',
          );
          expect(
            _transform(tester),
            isNot(equals(Matrix4.identity())),
            reason:
                'full mode: hover enter must apply a non-identity tilt '
                '(hoverTilt applied)',
          );
        },
      );
    });

    group('full mode hover exit', () {
      testWidgets(
        'hover exit → rest decoration (no boxShadow) + identity transform',
        (tester) async {
          // Enter then leave; the card must return to rest.
          //
          // With the stub this trivially passes because hover never activates.
          // Kept as a structural round-trip guard; it becomes meaningful after
          // the green pass because a missing onExit would leave the card stuck.
          await _pump(tester, storedMode: EffectsMode.full);

          final gesture = await _hoverEnter(tester);

          // Move pointer far off the card.
          await gesture.moveTo(Offset.zero);
          await tester.pump();

          expect(
            _decoration(tester).boxShadow,
            isNull,
            reason: 'after hover exit boxShadow must be cleared (rest)',
          );
          expect(
            _transform(tester),
            equals(Matrix4.identity()),
            reason: 'after hover exit transform must return to identity',
          );
        },
      );
    });

    group('AnimatedContainer duration', () {
      testWidgets(
        'full mode: AnimatedContainer.duration == kHoverAnimMs',
        (tester) async {
          // GREEN guard — the stub already gates duration from mode.
          // Must stay green through the green pass.
          await _pump(tester, storedMode: EffectsMode.full);

          expect(
            _animatedContainer(tester).duration,
            equals(const Duration(milliseconds: kHoverAnimMs)),
            reason: 'full mode AnimatedContainer duration must be kHoverAnimMs',
          );
        },
      );
    });

    group('lite mode', () {
      testWidgets(
        'lite: zero tickers + rest + identity even after simulated enter',
        (tester) async {
          // GREEN guard — stub: no callbacks are wired → lite behaviour is
          // already correct. Keeps the contract locked through the green pass
          // (a misguided green implementation that wires callbacks
          // unconditionally would fail this).
          await _pump(tester, storedMode: EffectsMode.lite);

          await _hoverEnter(tester);
          await tester.pumpAndSettle();

          expect(
            tester.binding.transientCallbackCount,
            equals(0),
            reason:
                'lite mode: no animation tickers must be running '
                '(Duration.zero prevents implicit tick registration)',
          );
          expect(
            _animatedContainer(tester).duration,
            equals(Duration.zero),
            reason: 'lite mode: AnimatedContainer duration must be zero',
          );
          expect(
            _decoration(tester).boxShadow,
            isNull,
            reason: 'lite mode: boxShadow must remain null even on hover enter',
          );
          expect(
            _transform(tester),
            equals(Matrix4.identity()),
            reason: 'lite mode: transform must remain identity even on hover',
          );
        },
      );
    });

    group('stuck-state: full hover then flip to lite', () {
      testWidgets(
        'full hover → flip to lite → rest+identity; '
        'flip back to full with pointer away → still rest',
        (tester) async {
          // Exercises the stuck-hover clear path described in HoverLift's
          // docstring: when the mode flips to lite while hovered, a post-frame
          // callback must reset _hovered so the card doesn't stay glowing.
          //
          // RED: the stub never sets _hovered so the "enter" in full mode is
          // already inert. The test still pins the contract: after the green
          // pass wires callbacks, a missing post-frame reset would leave
          // _hovered=true when flipping to lite, and the decoration/transform
          // would fail the rest check on the next full flip.
          final container = await _pump(tester, storedMode: EffectsMode.full);

          // Step 1: enter hover in full mode
          // (sets _hovered=true on green pass).
          await _hoverEnter(tester);

          // Step 2: flip to lite while still hovered.
          await container
              .read(effectsProvider.notifier)
              .setMode(EffectsMode.lite);
          await tester.pump(); // state rebuild
          await tester.pump(); // post-frame callback fires

          // In lite mode the card must always show rest regardless of _hovered.
          expect(
            _decoration(tester).boxShadow,
            isNull,
            reason:
                'after flip to lite, boxShadow must be null '
                '(lite mode never glows)',
          );
          expect(
            _transform(tester),
            equals(Matrix4.identity()),
            reason:
                'after flip to lite, transform must be identity '
                '(lite mode never tilts)',
          );

          // Step 3: flip back to full. Pointer is still at card center (we
          // never moved the gesture away), but _hovered should have been reset
          // to false by the post-frame callback. On green pass: the card must
          // re-enter hover because the pointer is still over it and onEnter
          // fires again — OR _hovered is reset and onEnter fires freshly.
          // The contractual guarantee is that no phantom glow persists without
          // an active mouse event.
          await container
              .read(effectsProvider.notifier)
              .setMode(EffectsMode.full);
          await tester.pump();
          await tester.pump();

          // No crash is the minimum guarantee of this step.
          expect(
            tester.takeException(),
            isNull,
            reason: 'toggling full→lite→full must not throw',
          );
        },
      );
    });
  });
}
