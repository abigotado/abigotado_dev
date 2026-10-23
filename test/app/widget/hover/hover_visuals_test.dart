import 'dart:math' as math;

import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/app/widget/hover/hover_visuals.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Representative resting decoration used across all tests in this file.
//
// Mirrors what MetricCard and SectionCard pass as restDecoration: a surface
// background, a muted hairline border, and a 12 px radius.
final _rest = BoxDecoration(
  color: AppColors.surface,
  border: Border.all(color: AppColors.border),
  borderRadius: const BorderRadius.all(Radius.circular(12)),
);

/// Projects the centre-relative point ([x], [y]) through [m] and returns the
/// homogeneous `w` (> 1 means the point recedes) and the projected point.
({double w, Offset projected}) _project(Matrix4 m, double x, double y) {
  final w = m.entry(3, 0) * x + m.entry(3, 1) * y + m.entry(3, 3);
  final px = m.entry(0, 0) * x + m.entry(0, 1) * y + m.entry(0, 3);
  final py = m.entry(1, 0) * x + m.entry(1, 1) * y + m.entry(1, 3);
  return (w: w, projected: Offset(px / w, py / w));
}

HoverPose _hoveredAt(Offset pointer, Size size) => hoverTargetPose(
  hovered: true,
  pointer: pointer,
  size: size,
  mode: EffectsMode.full,
);

/// The largest on-screen shift, along either axis, of any corner of a [size]
/// card under the full hover transform, with the pointer on each corner, each
/// edge midpoint and the centre.
double _worstCornerShift(Size size) {
  final hx = size.width / 2;
  final hy = size.height / 2;
  final corners = [
    for (final sx in [-1.0, 1.0])
      for (final sy in [-1.0, 1.0]) Offset(sx * hx, sy * hy),
  ];
  final pointers = [
    for (final sx in [-1.0, 0.0, 1.0])
      for (final sy in [-1.0, 0.0, 1.0]) Offset(sx * hx, sy * hy),
  ];
  var worst = 0.0;
  for (final pointer in pointers) {
    final m = hoverTransform(_hoveredAt(pointer + Offset(hx, hy), size));
    for (final c in corners) {
      final shift = _project(m, c.dx, c.dy).projected - c;
      worst = [worst, shift.dx.abs(), shift.dy.abs()].reduce(math.max);
    }
  }
  return worst;
}

void main() {
  group('hoverTargetPose', () {
    const size = Size(200, 100);
    const centre = Offset(100, 50);

    test('lite + hovered → rest, even with a pointer', () {
      expect(
        hoverTargetPose(
          hovered: true,
          pointer: Offset.zero,
          size: size,
          mode: EffectsMode.lite,
        ),
        same(HoverPose.rest),
      );
    });

    test('full + not hovered → rest', () {
      expect(
        hoverTargetPose(
          hovered: false,
          pointer: Offset.zero,
          size: size,
          mode: EffectsMode.full,
        ),
        same(HoverPose.rest),
      );
    });

    test('full + hovered without a pointer → lifted but flat', () {
      expect(
        hoverTargetPose(
          hovered: true,
          pointer: null,
          size: size,
          mode: EffectsMode.full,
        ),
        const HoverPose(
          rotateX: 0,
          rotateY: 0,
          scale: kHoverTiltScale,
          lift: 1,
        ),
      );
    });

    test('full + hovered at the centre → lifted but flat', () {
      expect(
        _hoveredAt(centre, size),
        const HoverPose(
          rotateX: 0,
          rotateY: 0,
          scale: kHoverTiltScale,
          lift: 1,
        ),
      );
    });

    test('a pointer past the edge clamps to the full tilt of a small card', () {
      // 200×100 is small enough that neither axis is capped below the max.
      expect(
        _hoveredAt(const Offset(-50, 300), size),
        const HoverPose(
          rotateX: kHoverMaxTiltRadians,
          rotateY: kHoverMaxTiltRadians,
          scale: kHoverTiltScale,
          lift: 1,
        ),
      );
    });

    group('the whole card moves at most kHoverMaxEdgeShift', () {
      // Wide-and-short, tall, and small cards: a cap derived from one axis'
      // extent alone lets a hovered corner drag the opposite one ~12 px.
      const cards = [
        Size(950, 300),
        Size(950, 900),
        Size(1000, 1000),
        Size(300, 120),
        Size(200, 100),
      ];

      for (final card in cards) {
        test('$card: no corner moves further, wherever the pointer is', () {
          expect(
            _worstCornerShift(card),
            lessThanOrEqualTo(kHoverMaxEdgeShift + 1e-9),
          );
        });
      }

      test('a large card spends the budget rather than freezing', () {
        expect(_worstCornerShift(const Size(950, 900)), greaterThan(3.5));
        expect(
          _hoveredAt(Offset.zero, const Size(950, 900)).rotateX,
          isNot(0),
        );
      });

      test('the lift scale takes at most half of the budget', () {
        final pose = _hoveredAt(const Offset(475, 150), const Size(950, 300));

        expect(
          (pose.scale - 1) * 950 / 2,
          closeTo(kHoverMaxEdgeShift / 2, 1e-9),
          reason:
              "a fixed 2% scale would push a 950 px card's edges out by "
              '9.5 px each',
        );
      });
    });
  });

  group('hoverTransform', () {
    test('rest → identity (no layer at rest)', () {
      expect(hoverTransform(HoverPose.rest), Matrix4.identity());
    });

    test('a tilted pose carries perspective', () {
      final m = hoverTransform(
        const HoverPose(rotateX: 0.03, rotateY: -0.03, scale: 1.01, lift: 1),
      );
      expect(m.entry(3, 2), isNot(0));
    });

    group('the edge under the cursor recedes', () {
      const size = Size(200, 100);

      test('pointer on the right edge → right edge recedes', () {
        final m = hoverTransform(_hoveredAt(const Offset(200, 50), size));
        expect(_project(m, 100, 0).w, greaterThan(1));
        expect(_project(m, -100, 0).w, lessThan(1));
      });

      test('pointer on the bottom edge → bottom edge recedes', () {
        final m = hoverTransform(_hoveredAt(const Offset(100, 100), size));
        expect(_project(m, 0, 50).w, greaterThan(1));
        expect(_project(m, 0, -50).w, lessThan(1));
      });
    });
  });

  group('hoverDecoration', () {
    test('lift 0 → rest unchanged', () {
      expect(hoverDecoration(lift: 0, rest: _rest), same(_rest));
    });

    test('lift 1 → accent border and full glow; colour/radius kept', () {
      final result = hoverDecoration(lift: 1, rest: _rest);
      final shadow = result.boxShadow!.single;

      expect((result.border! as Border).top.color, kHoverBorderColor);
      expect(shadow.color.a, closeTo(kHoverGlowOpacity, 1e-3));
      expect(shadow.blurRadius, kHoverGlowBlur);
      expect(result.color, _rest.color);
      expect(result.borderRadius, _rest.borderRadius);
    });

    test('lift 0.5 → half-strength glow (fades in, never pops)', () {
      final shadow = hoverDecoration(lift: 0.5, rest: _rest).boxShadow!.single;

      expect(shadow.color.a, closeTo(kHoverGlowOpacity / 2, 1e-3));
    });
  });
}
