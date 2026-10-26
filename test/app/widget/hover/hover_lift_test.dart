import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/app/widget/hover/hover_bounds.dart';
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

/// A child that counts how many times it is mounted, so a test can prove the
/// card content survives the hover round trip without being rebuilt from
/// scratch (a remount would replay the content's own reveal animations).
class _MountCounter extends StatefulWidget {
  const _MountCounter({required this.onMount});

  final VoidCallback onMount;

  @override
  State<_MountCounter> createState() => _MountCounterState();
}

class _MountCounterState extends State<_MountCounter> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  Widget build(BuildContext context) => const SizedBox(width: 200, height: 80);
}

// ---------------------------------------------------------------------------
// Shared rest decoration (same values MetricCard uses in production).
// ---------------------------------------------------------------------------

final _rest = BoxDecoration(
  color: AppColors.surface,
  border: Border.all(color: AppColors.border),
  borderRadius: const BorderRadius.all(Radius.circular(12)),
);

// ---------------------------------------------------------------------------
// Helper: pump HoverLift in a minimal harness.
//
// Returns the ProviderContainer so tests can call setMode on it.
// ---------------------------------------------------------------------------

Widget _centred(Widget card) => Center(child: card);

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required EffectsMode storedMode,
  Widget child = const SizedBox(width: 200, height: 80),
  Widget Function(Widget card) wrap = _centred,
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
        home: Scaffold(
          body: wrap(
            HoverLift(
              restDecoration: _rest,
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );

  return container;
}

// ---------------------------------------------------------------------------
// Helpers: read what HoverLift actually renders this frame (not its targets).
// ---------------------------------------------------------------------------

Finder _inHoverLift(Type type) =>
    find.descendant(of: find.byType(HoverLift), matching: find.byType(type));

List<Matrix4> _transforms(WidgetTester tester) => [
  for (final t in tester.widgetList<Transform>(_inHoverLift(Transform)))
    t.transform,
];

/// Every transform under the card is the identity: the card sits at rest.
bool _flat(WidgetTester tester) =>
    _transforms(tester).every((m) => m == Matrix4.identity());

/// Whether [m] projects with perspective (its bottom row is not 0,0,0,1).
bool _hasPerspective(Matrix4 m) =>
    m.entry(3, 0) != 0 ||
    m.entry(3, 1) != 0 ||
    m.entry(3, 2) != 0 ||
    m.entry(3, 3) != 1;

/// Whether [m] rotates the card at all (it is not a pure scale/translation).
bool _rotates(Matrix4 m) => m.entry(0, 2) != 0 || m.entry(1, 2) != 0;

List<DecoratedBox> _glowBoxes(WidgetTester tester) => [
  for (final box in tester.widgetList<DecoratedBox>(_inHoverLift(DecoratedBox)))
    if (box.decoration case BoxDecoration(
      :final boxShadow?,
    ) when boxShadow.isNotEmpty)
      box,
];

/// The blur of the single glow the card paints this frame.
double _glowBlur(WidgetTester tester) => switch (_glowBoxes(
  tester,
).single.decoration) {
  BoxDecoration(:final boxShadow?) => boxShadow.single.blurRadius,
  _ => throw StateError('no glow'),
};

// ---------------------------------------------------------------------------
// Helper: simulate the mouse entering the HoverLift centre.
// ---------------------------------------------------------------------------

Future<TestGesture> _hoverEnter(WidgetTester tester) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await gesture.moveTo(tester.getCenter(find.byType(HoverLift)));
  await tester.pump();
  return gesture;
}

Offset _offCentre(WidgetTester tester) =>
    tester.getCenter(find.byType(HoverLift)) + const Offset(80, 30);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('HoverLift', () {
    group('full mode', () {
      testWidgets('hover enter → glows and lifts', (tester) async {
        await _pump(tester, storedMode: EffectsMode.full);

        await _hoverEnter(tester);
        await tester.pumpAndSettle();

        expect(_glowBoxes(tester), isNotEmpty);
        expect(_flat(tester), isFalse, reason: 'the card must lift on hover');
      });

      testWidgets('tilt follows the pointer', (tester) async {
        await _pump(tester, storedMode: EffectsMode.full);

        final gesture = await _hoverEnter(tester);
        await tester.pumpAndSettle();
        final atCentre = _transforms(tester);

        await gesture.moveTo(_offCentre(tester));
        await tester.pumpAndSettle();

        expect(_transforms(tester), isNot(equals(atCentre)));
      });

      testWidgets(
        'retargets mid-flight keep the perspective tilt and continuity',
        (tester) async {
          // Regression: Matrix4Tween drops the perspective row for t < 1, so
          // following the cursor rendered the card flat and snapped it into
          // perspective only once the pointer had been still for kHoverAnimMs.
          await _pump(tester, storedMode: EffectsMode.full);

          final gesture = await _hoverEnter(tester);
          await tester.pumpAndSettle();

          await gesture.moveTo(_offCentre(tester));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: kHoverAnimMs ~/ 4));
          final before = _transforms(tester).single;

          // Retarget again while the first tween is still running.
          final centre = tester.getCenter(find.byType(HoverLift));
          await gesture.moveTo(centre - const Offset(80, 30));
          await tester.pump();
          final after = _transforms(tester).single;
          await tester.pump(const Duration(milliseconds: kHoverAnimMs ~/ 2));
          final later = _transforms(tester).single;

          for (final m in [before, after, later]) {
            expect(
              _hasPerspective(m) && _rotates(m),
              isTrue,
              reason: 'every frame of a retarget must lean in perspective',
            );
          }
          expect(
            (after.entry(0, 2) - before.entry(0, 2)).abs(),
            lessThan((later.entry(0, 2) - before.entry(0, 2)).abs()),
            reason:
                'the retarget must continue from the current lean, not jump, '
                'and keep moving toward the new target',
          );
        },
      );

      testWidgets('hover exit eases the tilt out in perspective', (
        tester,
      ) async {
        await _pump(tester, storedMode: EffectsMode.full);

        final gesture = await _hoverEnter(tester);
        await gesture.moveTo(_offCentre(tester));
        await tester.pumpAndSettle();

        await gesture.moveTo(Offset.zero);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: kHoverAnimMs ~/ 2));

        expect(
          _transforms(tester).any(_hasPerspective),
          isTrue,
          reason: 'the exit must ease back, not drop the perspective at once',
        );
      });

      testWidgets('hover exit → rest: no glow, flat', (tester) async {
        await _pump(tester, storedMode: EffectsMode.full);

        final gesture = await _hoverEnter(tester);
        await tester.pumpAndSettle();

        await gesture.moveTo(Offset.zero);
        await tester.pumpAndSettle();

        expect(_glowBoxes(tester), isEmpty);
        expect(_flat(tester), isTrue);
      });

      testWidgets('the card content is not remounted by a hover round trip', (
        tester,
      ) async {
        var mounts = 0;
        await _pump(
          tester,
          storedMode: EffectsMode.full,
          child: _MountCounter(onMount: () => mounts++),
        );

        final gesture = await _hoverEnter(tester);
        await gesture.moveTo(_offCentre(tester));
        await tester.pumpAndSettle();
        await gesture.moveTo(Offset.zero);
        await tester.pumpAndSettle();

        expect(mounts, 1);
      });
    });

    group('glow room', () {
      testWidgets('the glow is full size outside any HoverBounds', (
        tester,
      ) async {
        await _pump(tester, storedMode: EffectsMode.full);

        await _hoverEnter(tester);
        await tester.pumpAndSettle();

        expect(_glowBlur(tester), kHoverGlowBlur);
      });

      testWidgets(
        'next to a HoverBounds edge the glow shrinks to fade out before it',
        (tester) async {
          // The card sits 24 px from the bounds' right edge and 100 px from its
          // left: the tighter side decides.
          await _pump(
            tester,
            storedMode: EffectsMode.full,
            wrap: (card) => HoverBounds(
              child: ClipRect(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 100),
                    child: SizedBox(width: 432 - 100 - 24, child: card),
                  ),
                ),
              ),
            ),
            surfaceSize: const Size(432, 400),
          );

          await _hoverEnter(tester);
          await tester.pumpAndSettle();

          expect(_glowBlur(tester), hoverGlowBlurFor(24));
        },
      );
    });

    group('lite mode', () {
      testWidgets('no ticker, no glow, flat — even on hover', (tester) async {
        await _pump(tester, storedMode: EffectsMode.lite);

        await _hoverEnter(tester);

        expect(
          tester.binding.transientCallbackCount,
          0,
          reason: 'lite mode must not run any animation ticker',
        );
        expect(_glowBoxes(tester), isEmpty);
        expect(_flat(tester), isTrue);
      });
    });

    group('stuck-state: full hover then flip to lite', () {
      testWidgets(
        'flip to lite renders rest; leaving in lite and flipping back to '
        'full leaves no phantom hover',
        (tester) async {
          final container = await _pump(tester, storedMode: EffectsMode.full);

          final gesture = await _hoverEnter(tester);
          await gesture.moveTo(_offCentre(tester));
          await tester.pumpAndSettle();

          await container
              .read(effectsProvider.notifier)
              .setMode(EffectsMode.lite);
          await tester.pump(); // state rebuild
          await tester.pump(); // post-frame reset fires

          expect(_glowBoxes(tester), isEmpty);
          expect(_flat(tester), isTrue);

          // Leave while in lite: no onExit is wired, so only the post-frame
          // reset can have cleared the hover.
          await gesture.moveTo(Offset.zero);
          await tester.pump();

          await container
              .read(effectsProvider.notifier)
              .setMode(EffectsMode.full);
          await tester.pumpAndSettle();

          expect(
            _glowBoxes(tester),
            isEmpty,
            reason: 'a hover cleared in lite must not come back in full',
          );
          expect(_flat(tester), isTrue);
        },
      );
    });
  });
}
