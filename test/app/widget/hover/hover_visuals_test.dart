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
    group('lite mode', () {
      test('lite + hovered:true → identity matrix', () {
        // Key lite-mode guard: no 3-D transform ever emitted in lite.
        // Red phase: throws UnimplementedError.
        expect(
          hoverTilt(hovered: true, mode: EffectsMode.lite),
          equals(Matrix4.identity()),
        );
      });
    });

    group('full mode', () {
      test('full + hovered:false → identity matrix', () {
        // Not hovered → no transform, regardless of mode.
        // Red phase: throws UnimplementedError.
        expect(
          hoverTilt(hovered: false, mode: EffectsMode.full),
          equals(Matrix4.identity()),
        );
      });

      test('full + hovered:true → fixed tilt (not identity)', () {
        // Two assertions:
        // 1. The result is NOT identity (the transform is actually applied).
        // 2. The result equals the exact matrix built from the public constants
        //    — the tilt must be deterministic, not cursor-tracked.
        //
        // Red phase: throws UnimplementedError.

        final expected = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(kHoverTiltRadians)
          ..rotateY(-kHoverTiltRadians)
          ..scaleByDouble(
            kHoverTiltScale,
            kHoverTiltScale,
            kHoverTiltScale,
            1,
          );

        final result = hoverTilt(hovered: true, mode: EffectsMode.full);

        expect(
          result,
          isNot(equals(Matrix4.identity())),
          reason: 'full+hovered must produce a non-identity transform',
        );
        expect(
          result,
          equals(expected),
          reason:
              'full+hovered must equal the pinned tilt matrix built from '
              'kHoverTiltRadians, kHoverTiltScale and 0.001 perspective entry',
        );
      });
    });
  });
}
