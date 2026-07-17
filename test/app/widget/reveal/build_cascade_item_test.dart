import 'package:abigotado_dev/src/app/widget/reveal/build_cascade_item.dart';
import 'package:abigotado_dev/src/app/widget/reveal/section_build_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// BuildCascadeItem has zero Riverpod/effects dependency — SectionBuildScope
// is a plain InheritedWidget — so these harnesses need no ProviderScope.
//
// The "animated branch" (SectionBuildScope present) is unreachable in the
// CONTRACTS pass: `_AnimatedCascadeItem.build` throws UnimplementedError
// unconditionally, regardless of index/count/progress — so every scoped test
// below is RED for the same underlying reason. The "static branch" (no
// scope) test is BORN-GREEN — it pins the byte-identical passthrough that
// MetricsSection/ChangelogCard/PubspecCard already depend on to keep their
// own goldens/tests stable through this pass.
// ---------------------------------------------------------------------------

const Size _surface = Size(400, 300);
const Widget _probe = SizedBox(
  width: 80,
  height: 40,
  child: Center(child: Text('cascade-probe')),
);

Future<void> _setSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(_surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _pumpBare(WidgetTester tester, Widget child) async {
  await _setSurface(tester);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

Future<void> _pumpItem(
  WidgetTester tester, {
  required int index,
  required int count,
  required Widget child,
  double? progress,
}) async {
  await _setSurface(tester);
  final item = BuildCascadeItem(index: index, count: count, child: child);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: progress == null
              ? item
              : SectionBuildScope(
                  progress: AlwaysStoppedAnimation<double>(progress),
                  child: item,
                ),
        ),
      ),
    ),
  );
}

Opacity _itemOpacity(WidgetTester tester) => tester.widget<Opacity>(
  find.descendant(
    of: find.byType(BuildCascadeItem),
    matching: find.byType(Opacity),
  ),
);

void main() {
  group('BuildCascadeItem', () {
    group('static branch (no SectionBuildScope)', () {
      testWidgets(
        // Passes on stub — must STAY green: pins the byte-identical
        // passthrough MetricsSection/ChangelogCard/PubspecCard depend on.
        'child renders verbatim — same widget instance, identical size, no '
        'extra layout box',
        (tester) async {
          // Baseline: the probe's natural size with no BuildCascadeItem
          // wrapper at all.
          await _pumpBare(tester, _probe);
          final baselineSize = tester.getSize(find.byWidget(_probe));

          await _pumpItem(tester, index: 0, count: 1, child: _probe);

          expect(
            find.byWidget(_probe),
            findsOneWidget,
            reason:
                'BuildCascadeItem must return child unchanged — the '
                'exact same widget instance, not a rebuilt equivalent',
          );
          expect(
            find.descendant(
              of: find.byType(BuildCascadeItem),
              matching: find.byType(Opacity),
            ),
            findsNothing,
            reason: 'the static branch must add no Opacity wrapper',
          );
          expect(
            find.descendant(
              of: find.byType(BuildCascadeItem),
              matching: find.byType(FractionalTranslation),
            ),
            findsNothing,
            reason:
                'the static branch must add no FractionalTranslation '
                'wrapper',
          );
          expect(
            tester.getSize(find.byWidget(_probe)),
            equals(baselineSize),
            reason:
                'wrapping in BuildCascadeItem (no scope) must not '
                'change the layout size of the child',
          );
        },
      );
    });

    group('animated branch (SectionBuildScope present)', () {
      group('v=0, index 1 of 3 (interval begins > 0)', () {
        testWidgets(
          'opacity is 0, but semantics stay reachable (alwaysIncludeSemantics)',
          (tester) async {
            final handle = tester.ensureSemantics();

            await _pumpItem(
              tester,
              index: 1,
              count: 3,
              child: _probe,
              progress: 0,
            );

            expect(_itemOpacity(tester).opacity, equals(0.0));
            expect(
              find.bySemanticsLabel('cascade-probe'),
              findsOneWidget,
              reason:
                  'mid-cascade content is genuinely present, so its '
                  'semantics must stay reachable at every opacity — mirrors '
                  'the alwaysIncludeSemantics contract in '
                  'reveal_on_scroll.dart',
            );

            handle.dispose();
          },
        );
      });

      group('v=1', () {
        testWidgets(
          'opacity is 1 and translation is zero — same position as the '
          'no-scope (static) render',
          (tester) async {
            await _pumpItem(tester, index: 0, count: 3, child: _probe);
            final staticTopLeft = tester.getTopLeft(find.byWidget(_probe));

            await _pumpItem(
              tester,
              index: 0,
              count: 3,
              child: _probe,
              progress: 1,
            );

            expect(_itemOpacity(tester).opacity, equals(1.0));
            expect(
              tester.getTopLeft(find.byWidget(_probe)),
              equals(staticTopLeft),
              reason:
                  'a settled cascade item must sit at the exact same '
                  'position as the static render — zero residual '
                  'translation',
            );
          },
        );
      });

      group('size stability', () {
        testWidgets(
          'rendered size is identical at v=0, 0.5, and 1 (paint-only '
          'wrappers must never affect layout)',
          (tester) async {
            final sizes = <double, Size>{};
            for (final v in [0.0, 0.5, 1.0]) {
              await _pumpItem(
                tester,
                index: 1,
                count: 3,
                child: _probe,
                progress: v,
              );
              sizes[v] = tester.getSize(find.byWidget(_probe));
            }

            final settled = sizes[1.0];
            for (final v in [0.0, 0.5]) {
              expect(
                sizes[v],
                equals(settled),
                reason:
                    'size at v=$v (${sizes[v]}) must match the settled '
                    'size ($settled)',
              );
            }
          },
        );
      });

      group('count=1 (the clamp)', () {
        testWidgets(
          'index=0 renders without throwing at v=0, 0.5, and 1',
          (tester) async {
            for (final v in [0.0, 0.5, 1.0]) {
              await _pumpItem(
                tester,
                index: 0,
                count: 1,
                child: _probe,
                progress: v,
              );
              expect(
                tester.takeException(),
                isNull,
                reason:
                    'count=1 must never divide by zero or throw, at any '
                    'progress value (v=$v)',
              );
            }
          },
        );
      });
    });
  });
}
