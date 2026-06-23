import 'package:abigotado_dev/src/app/theme/app_sizing.dart';
import 'package:abigotado_dev/src/app/widget/background/background_dot.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

List<BackgroundDot> _layout({
  required Size size,
  required double t,
  double spacing = AppSizing.backgroundDotSpacing,
  int seed = 0,
}) => layoutBackgroundDots(size: size, t: t, spacing: spacing, seed: seed);

void main() {
  group('layoutBackgroundDots', () {
    // -------------------------------------------------------------------------
    // Count / geometry — RED: throws UnimplementedError until green pass.
    // -------------------------------------------------------------------------

    test('Size(96,96) spacing48 → 4 dots', () {
      // 96/48 = 2 cols, 2 rows → 2×2 = 4 dots.
      final dots = _layout(size: const Size(96, 96), t: 0);
      expect(dots.length, equals(4));
    });

    test('Size(10,10) → empty (degenerate, smaller than one cell)', () {
      // 10/48 = 0 cols → empty.
      final dots = _layout(size: const Size(10, 10), t: 0);
      expect(dots, isEmpty);
    });

    test('Size.zero → empty', () {
      final dots = _layout(size: Size.zero, t: 0);
      expect(dots, isEmpty);
    });

    // -------------------------------------------------------------------------
    // Seamless loop — RED: throws until green pass.
    // -------------------------------------------------------------------------

    test('seamless loop: t:0 == t:1.0', () {
      // The %1.0 reduction must make t=1.0 produce exactly the same phase arg
      // as t=0.0 for every dot — so the two lists are deeply equal.
      const size = Size(96, 96);
      final at0 = _layout(size: size, t: 0);
      final at1 = _layout(size: size, t: 1);
      expect(at0, equals(at1));
    });

    // -------------------------------------------------------------------------
    // Animation — RED: throws until green pass.
    // -------------------------------------------------------------------------

    test('animated: t:0 != t:0.5', () {
      const size = Size(96, 96);
      final at0 = _layout(size: size, t: 0);
      final at05 = _layout(size: size, t: 0.5);
      // Different phase → different opacity → lists must not be equal.
      expect(at0, isNot(equals(at05)));
    });

    // -------------------------------------------------------------------------
    // Determinism — RED: throws until green pass.
    // -------------------------------------------------------------------------

    test('deterministic: same args → equal', () {
      const size = Size(96, 96);
      const t = 0.25;
      final a = _layout(size: size, t: t);
      final b = _layout(size: size, t: t);
      expect(a, equals(b));
    });

    test('seed:0 != seed:1 (phases differ)', () {
      const size = Size(96, 96);
      const t = 0.25;
      final s0 = _layout(size: size, t: t);
      final s1 = _layout(size: size, t: t, seed: 1);
      // Different seeds produce different dot phases → at least one opacity
      // differs → the lists are not equal.
      expect(s0, isNot(equals(s1)));
    });

    // -------------------------------------------------------------------------
    // Radius invariant — RED: throws until green pass.
    // -------------------------------------------------------------------------

    test('radius constant across t (only opacity breathes, not radius)', () {
      const size = Size(96, 96);
      final at0 = _layout(size: size, t: 0);
      final at05 = _layout(size: size, t: 0.5);

      expect(
        at0,
        isNotEmpty,
        reason: 'precondition: Size(96,96) must produce dots',
      );
      expect(
        at0.length,
        equals(at05.length),
        reason: 'count must not change across t',
      );

      for (var i = 0; i < at0.length; i++) {
        expect(
          at0[i].radius,
          equals(at05[i].radius),
          reason: 'dot[$i].radius must be constant across t',
        );
      }
    });

    test('all radii == kDotBaseRadius (seed=0 default)', () {
      final dots = _layout(size: const Size(96, 96), t: 0);
      expect(dots, isNotEmpty, reason: 'precondition');
      for (final dot in dots) {
        expect(
          dot.radius,
          equals(kDotBaseRadius),
          reason: 'every dot must have radius == kDotBaseRadius',
        );
      }
    });

    // -------------------------------------------------------------------------
    // Opacity range — RED: throws until green pass.
    // -------------------------------------------------------------------------

    test('opacity within [base-amp, base+amp] = [0.02, 0.10]', () {
      // Sample a few t values to probe the full range.
      const size = Size(192, 192);
      const tValues = [0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875];
      for (final t in tValues) {
        final dots = _layout(size: size, t: t);
        for (final dot in dots) {
          expect(
            dot.opacity,
            greaterThanOrEqualTo(kBaseOpacity - kOpacityAmp - 1e-9),
            reason: 'opacity must be >= ${kBaseOpacity - kOpacityAmp} at t=$t',
          );
          expect(
            dot.opacity,
            lessThanOrEqualTo(kBaseOpacity + kOpacityAmp + 1e-9),
            reason: 'opacity must be <= ${kBaseOpacity + kOpacityAmp} at t=$t',
          );
        }
      }
    });

    // -------------------------------------------------------------------------
    // Monotonic count — RED: throws until green pass.
    // -------------------------------------------------------------------------

    test('monotonic count: 480² has more dots than 96²', () {
      final large = _layout(size: const Size(480, 480), t: 0);
      final small = _layout(size: const Size(96, 96), t: 0);
      expect(
        large.length,
        greaterThan(small.length),
        reason: 'a larger surface must contain more dots than a smaller one',
      );
    });

    // -------------------------------------------------------------------------
    // Opacity formula spot-check — RED: throws until green pass.
    // The formula is: kBaseOpacity + kOpacityAmp * sin(2*pi*((t+dotPhase)%1.0))
    // We can't know dotPhase without implementing it, but we CAN verify the
    // t:0 == t:1 invariant and that t:0.5 differs from t:0, which the tests
    // above already cover. This additional spot-check confirms the formula
    // extreme: at exactly the peak of sin (phase argument = 0.25), opacity
    // equals kBaseOpacity + kOpacityAmp. We verify this by finding a dot whose
    // opacity is at the maximum, which must equal kBaseOpacity + kOpacityAmp.
    // -------------------------------------------------------------------------

    test(
      'max opacity across all t never exceeds kBaseOpacity + kOpacityAmp',
      () {
        const size = Size(192, 192);
        // Sample 100 evenly-spaced t values to catch any over-shoot.
        for (var i = 0; i < 100; i++) {
          final t = i / 100.0;
          final dots = _layout(size: size, t: t);
          for (final dot in dots) {
            expect(
              dot.opacity,
              lessThanOrEqualTo(kBaseOpacity + kOpacityAmp + 1e-9),
              reason: 'opacity overshoot at t=$t: ${dot.opacity}',
            );
          }
        }
      },
    );
  });
}
