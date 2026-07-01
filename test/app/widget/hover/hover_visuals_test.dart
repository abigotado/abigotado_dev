import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/app/widget/hover/hover_visuals.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Representative resting decoration used across all tests in this file.
//
// Mirrors what MetricCard and SectionCard pass as restDecoration: a surface
// background, a muted hairline border, and a 12 px radius. These fields must
// survive round-trips through hoverDecoration unchanged when the mode is lite
// or the card is not hovered.
const _rest = BoxDecoration(
  color: AppColors.surface,
  border: Border.symmetric(
    horizontal: BorderSide(color: AppColors.border),
    vertical: BorderSide(color: AppColors.border),
  ),
  borderRadius: BorderRadius.all(Radius.circular(12)),
);

void main() {
  group('hoverDecoration', () {
    group('lite mode', () {
      test('lite + hovered:true → returns rest unchanged', () {
        // Key red test: proves lite mode never adds a glow regardless of the
        // hovered flag. The stub throws UnimplementedError → test fails with
        // that error instead of the expected equality.
        expect(
          hoverDecoration(
            hovered: true,
            mode: EffectsMode.lite,
            rest: _rest,
          ),
          same(_rest),
        );
      });

      test('lite + hovered:false → returns rest unchanged', () {
        // Symmetry guard: lite with no hover must also return rest.
        // Also fails with UnimplementedError in the red phase.
        expect(
          hoverDecoration(
            hovered: false,
            mode: EffectsMode.lite,
            rest: _rest,
          ),
          same(_rest),
        );
      });
    });

    group('full mode', () {
      test('full + hovered:false → returns rest unchanged', () {
        // Not hovered in full mode must also be a no-op.
        // Fails with UnimplementedError in the red phase.
        expect(
          hoverDecoration(
            hovered: false,
            mode: EffectsMode.full,
            rest: _rest,
          ),
          same(_rest),
        );
      });

      test('full + hovered:true → glow decoration applied', () {
        // The main behavior test for the green pass.
        // Red phase: throws UnimplementedError.
        // Green phase: result must have the accent glow.
        final result = hoverDecoration(
          hovered: true,
          mode: EffectsMode.full,
          rest: _rest,
        );

        // --- border: all sides use kHoverBorderColor ---
        final border = result.border;
        expect(
          border,
          isNotNull,
          reason: 'hovered decoration must have a border',
        );
        final topColor = (border! as Border).top.color;
        expect(
          topColor,
          equals(kHoverBorderColor),
          reason: 'border color must be kHoverBorderColor on hover',
        );

        // --- boxShadow: exactly one glow shadow ---
        expect(
          result.boxShadow,
          isNotNull,
          reason: 'hovered decoration must have a boxShadow',
        );
        expect(
          result.boxShadow!.length,
          equals(1),
          reason: 'exactly one BoxShadow is added on hover',
        );

        // --- rest fields preserved: color and radius ---
        expect(
          result.color,
          equals(_rest.color),
          reason: 'hoverDecoration must preserve the rest background color',
        );
        expect(
          result.borderRadius,
          equals(_rest.borderRadius),
          reason: 'hoverDecoration must preserve the rest border radius',
        );
      });
    });
  });

  group('hoverTilt', () {
    const size = Size(200, 100);
    const centre = Offset(100, 50);

    test('lite + hovered → identity even with a pointer', () {
      // No 3-D transform is ever emitted in lite, regardless of the pointer.
      expect(
        hoverTilt(
          hovered: true,
          pointer: centre,
          size: size,
          mode: EffectsMode.lite,
        ),
        equals(Matrix4.identity()),
      );
    });

    test('full + not hovered → identity', () {
      expect(
        hoverTilt(
          hovered: false,
          pointer: centre,
          size: size,
          mode: EffectsMode.full,
        ),
        equals(Matrix4.identity()),
      );
    });

    test('full + hovered + pointer at centre → non-identity (scale lift)', () {
      // At the centre the tilt angle is zero, but the card still lifts: the
      // perspective projection + uniform scale make the matrix non-identity.
      expect(
        hoverTilt(
          hovered: true,
          pointer: centre,
          size: size,
          mode: EffectsMode.full,
        ),
        isNot(equals(Matrix4.identity())),
      );
    });

    test('full + hovered: off-centre tilt differs from centre (tracked)', () {
      final centred = hoverTilt(
        hovered: true,
        pointer: centre,
        size: size,
        mode: EffectsMode.full,
      );
      final corner = hoverTilt(
        hovered: true,
        pointer: Offset.zero,
        size: size,
        mode: EffectsMode.full,
      );
      expect(
        corner,
        isNot(equals(centred)),
        reason:
            'the tilt must track the pointer — a corner hover and a centre '
            'hover cannot produce the same matrix',
      );
    });

    test('full + hovered: left and right pointers tilt oppositely', () {
      const left = Offset(0, 50);
      const right = Offset(200, 50);
      expect(
        hoverTilt(
          hovered: true,
          pointer: left,
          size: size,
          mode: EffectsMode.full,
        ),
        isNot(
          equals(
            hoverTilt(
              hovered: true,
              pointer: right,
              size: size,
              mode: EffectsMode.full,
            ),
          ),
        ),
        reason: 'horizontal pointer position must flip the Y-rotation',
      );
    });
  });
}
