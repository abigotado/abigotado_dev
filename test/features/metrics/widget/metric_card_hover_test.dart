import 'package:abigotado_dev/src/app/widget/hover/hover_lift.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/core/effects/effects_store.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/features/metrics/widget/metric_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake
// ---------------------------------------------------------------------------

/// An [EffectsStore] that always returns lite mode (cards render hover-inert).
///
/// Using lite mode here ensures HoverLift never activates any hover behaviour,
/// keeping this test focused on the structural a11y contract.
final class _FakeEffectsStore implements EffectsStore {
  const _FakeEffectsStore();

  @override
  EffectsMode? read() => EffectsMode.lite;

  @override
  Future<void> write(EffectsMode mode) async {}

  @override
  Future<void> clear() async {}
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('MetricCard', () {
    group('a11y invariant: HoverLift adds no semantics nodes', () {
      testWidgets(
        'semantics label unchanged; '
        'exactly one ExcludeSemantics; '
        'HoverLift subtree contains no Semantics',
        (tester) async {
          // ensureSemantics disposed in-body (not via addTearDown) to avoid
          // the Flutter 3.44 footgun where the handle outlives the widget tree
          // and the ensureSemantics assertion fires on the NEXT test.
          final handle = tester.ensureSemantics();

          await tester.binding.setSurfaceSize(const Size(800, 400));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          const semanticsLabel = 'app size: from 75 to 40 megabytes';

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                effectsStoreProvider.overrideWithValue(
                  const _FakeEffectsStore(),
                ),
              ],
              child: const MaterialApp(
                debugShowCheckedModeBanner: false,
                home: Scaffold(
                  body: Center(
                    child: MetricCard(
                      value: '75 → 40 MB',
                      label: 'app size',
                      semanticsLabel: semanticsLabel,
                    ),
                  ),
                ),
              ),
            ),
          );

          // --- the card's accessible label is the semanticsLabel ---
          final node = tester.getSemantics(find.byType(MetricCard));
          expect(
            node.label,
            equals(semanticsLabel),
            reason:
                'MetricCard semantics label must equal the semanticsLabel '
                'constructor argument',
          );

          // --- exactly one ExcludeSemantics lives inside MetricCard ---
          // MetricCard wraps HoverLift in ExcludeSemantics; HoverLift itself
          // must NOT add an additional ExcludeSemantics.
          expect(
            find.descendant(
              of: find.byType(MetricCard),
              matching: find.byType(ExcludeSemantics),
            ),
            findsOneWidget,
            reason:
                'MetricCard must have exactly one ExcludeSemantics '
                '(the one it owns around HoverLift + card content)',
          );

          // --- HoverLift introduces no Semantics node of its own ---
          // HoverLift is pure chrome (MouseRegion + AnimatedContainer). Adding
          // a Semantics node would either double-announce or obscure the parent
          // Semantics label.
          expect(
            find.descendant(
              of: find.byType(HoverLift),
              matching: find.byType(Semantics),
            ),
            findsNothing,
            reason:
                'HoverLift must not add any Semantics node; '
                'a11y is the responsibility of the card wrapper',
          );

          handle.dispose();
        },
      );
    });
  });
}
