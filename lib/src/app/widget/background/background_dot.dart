import 'dart:math';

import 'package:abigotado_dev/src/app/theme/app_sizing.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/painting.dart';

/// Base opacity of each background dot when the animation phase is 0.
const double kBaseOpacity = 0.06;

/// Half-amplitude of the sinusoidal opacity pulse around [kBaseOpacity].
///
/// Effective opacity range: `[kBaseOpacity - kOpacityAmp,
/// kBaseOpacity + kOpacityAmp]` = `[0.02, 0.10]`.
const double kOpacityAmp = 0.04;

/// Constant logical-pixel radius for every background dot.
const double kDotBaseRadius = 1.5;

/// An immutable snapshot of a single background grid dot.
///
/// [position] is the dot's centre in the CustomPainter local coordinate space.
/// [radius] is always [kDotBaseRadius] (constant per dot). [opacity] is driven
/// by the animation phase `t` at layout time — see [layoutBackgroundDots].
final class BackgroundDot extends Equatable {
  /// Creates an immutable background-dot descriptor.
  const BackgroundDot({
    required this.position,
    required this.radius,
    required this.opacity,
  });

  /// Centre of the dot in the painter's local coordinate space.
  final Offset position;

  /// Logical-pixel radius of the dot.
  final double radius;

  /// Current opacity in the range `[0.0, 1.0]`.
  final double opacity;

  @override
  List<Object?> get props => [position, radius, opacity];
}

/// Lays out the full set of background dots for a [size] at animation
/// phase [t].
///
/// The grid is deterministic and floor-anchored:
///
/// ```dart
/// cols = (size.width  / spacing).floor()
/// rows = (size.height / spacing).floor()
/// ```
///
/// Dot centres are positioned at `((col + 0.5) * spacing, (row + 0.5) *
/// spacing)`, keeping every dot fully inset from the canvas edge. A degenerate
/// or zero [size] returns an empty list.
///
/// Per-dot opacity is computed as:
///
/// ```dart
/// opacity = kBaseOpacity + kOpacityAmp * sin(2 * pi * ((t + dotPhase) % 1.0))
/// ```
///
/// `dotPhase` is a deterministic integer bit-mix of `(col, row, seed)` — no
/// `Random` instantiation per call. The `% 1.0` makes the loop seamless:
/// `t=0.0` and `t=1.0` produce identical output.
///
/// Every dot's [BackgroundDot.radius] is the constant [kDotBaseRadius].
List<BackgroundDot> layoutBackgroundDots({
  required Size size,
  required double t,
  double spacing = AppSizing.backgroundDotSpacing,
  int seed = 0,
}) {
  if (size.width <= 0 || size.height <= 0 || spacing <= 0) return const [];
  final cols = (size.width / spacing).floor();
  final rows = (size.height / spacing).floor();
  // Centre the grid: split the per-axis remainder evenly so the margins match
  // on both sides instead of pooling on the bottom/right.
  final originX = (size.width - cols * spacing) / 2;
  final originY = (size.height - rows * spacing) / 2;
  final dots = <BackgroundDot>[];
  for (var row = 0; row < rows; row++) {
    for (var col = 0; col < cols; col++) {
      final dotPhase = _phaseFor(col, row, seed);
      final theta = 2 * pi * ((t + dotPhase) % 1.0);
      final opacity = kBaseOpacity + kOpacityAmp * sin(theta);
      dots.add(
        BackgroundDot(
          position: Offset(
            originX + (col + 0.5) * spacing,
            originY + (row + 0.5) * spacing,
          ),
          radius: kDotBaseRadius,
          opacity: opacity,
        ),
      );
    }
  }
  return dots;
}

/// Deterministic per-dot phase in [0, 1) from grid coords and seed.
///
/// Uses integer bit-mixing — no [Random] instantiation per call.
double _phaseFor(int col, int row, int seed) {
  final h = (col * 73856093) ^ (row * 19349663) ^ (seed * 83492791);
  return (h & 0xFFFF) / 0x10000;
}
