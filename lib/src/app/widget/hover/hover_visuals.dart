import 'dart:math' as math;

import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Duration in milliseconds for the hover enter/exit transition.
const int kHoverAnimMs = 160;

/// Border color applied to a card's decoration while hovered in full mode.
const Color kHoverBorderColor = AppColors.accentPurple;

/// Blur radius (logical pixels) for the glow box-shadow added on hover.
const double kHoverGlowBlur = 24;

/// Opacity of the glow box-shadow added on hover.
const double kHoverGlowOpacity = 0.33;

/// How far the glow visibly reaches past the card edge, in glow sigmas.
///
/// Beyond 2.5σ a straight edge's blurred shadow is below 0.7% of its peak; at
/// [kHoverGlowOpacity] in [kHoverBorderColor] that is under half an 8-bit step
/// over the page background, so the glow reads as fully faded there.
const double kHoverGlowReachSigmas = 2.5;

/// Maximum perspective-tilt angle (radians) reached at a card's edges while
/// hovered in full mode.
///
/// Approximately 3.5 degrees. The tilt is cursor-tracked: the angle on each
/// axis scales with the pointer's distance from the card centre — zero at the
/// centre, this value at the edge — so the card leans toward the cursor.
/// Large cards lean less: see [kHoverMaxEdgeShift].
const double kHoverMaxTiltRadians = 0.06;

/// Scale factor applied together with the tilt while hovered in full mode.
///
/// Large cards scale less: see [kHoverMaxEdgeShift].
const double kHoverTiltScale = 1.02;

/// Perspective strength of the hover tilt: the `[3][2]` entry of the tilt
/// matrix, i.e. the reciprocal of the eye's distance (≈ 1000 logical px).
const double kHoverPerspective = 0.001;

/// Upper bound, in logical pixels, on how far the hover moves any corner of a
/// card on screen along either axis, tilt and lift scale combined.
///
/// With a fixed angle the projected shift of a corner grows with the square of
/// the card's size, and a fixed scale grows it linearly, so a tall file card
/// would swing and swell by tens of pixels under the same hover that barely
/// moves a metric card. [hoverTargetPose] splits this budget per card: the
/// lift scale takes at most half, the perspective tilt the rest. Small cards
/// keep the full [kHoverMaxTiltRadians] and [kHoverTiltScale]; large cards
/// move proportionally less.
const double kHoverMaxEdgeShift = 4;

/// The animated hover state of one card.
///
/// `HoverLift` interpolates this value — never a [Matrix4] — and rebuilds the
/// matrix and decoration from it on every frame. `Matrix4Tween` decomposes a
/// matrix into translation/rotation/scale and recomposes it, which silently
/// drops the perspective row, so tweening the matrix itself renders the card
/// flat mid-animation and snaps it into perspective at the end.
final class HoverPose extends Equatable {
  /// Creates a hover pose.
  const HoverPose({
    required this.rotateX,
    required this.rotateY,
    required this.scale,
    required this.lift,
  });

  /// Linearly interpolates every field between [a] and [b].
  HoverPose.lerp(HoverPose a, HoverPose b, double t)
    : rotateX = a.rotateX + (b.rotateX - a.rotateX) * t,
      rotateY = a.rotateY + (b.rotateY - a.rotateY) * t,
      scale = a.scale + (b.scale - a.scale) * t,
      lift = a.lift + (b.lift - a.lift) * t;

  /// The resting pose: no tilt, no scale, no lift.
  static const HoverPose rest = HoverPose(
    rotateX: 0,
    rotateY: 0,
    scale: 1,
    lift: 0,
  );

  /// Rotation about the card's horizontal axis, in radians (already capped).
  final double rotateX;

  /// Rotation about the card's vertical axis, in radians (already capped).
  final double rotateY;

  /// Uniform scale of the card (already capped); `1` at rest.
  final double scale;

  /// Hover progress: `0` at rest, `1` fully hovered. Drives the border colour
  /// and the glow.
  final double lift;

  @override
  List<Object?> get props => [rotateX, rotateY, scale, lift];
}

/// The pose a card of [size] animates toward for the current hover input.
///
/// **Contracts**:
/// - [EffectsMode.lite] or `!hovered` → [HoverPose.rest] (same instance).
/// - `full + hovered` → `lift: 1`; an empty [size] gets the full
///   [kHoverTiltScale] and no tilt.
/// - the lift scale grows the longest side's half `L` by
///   `min((kHoverTiltScale - 1) * L, kHoverMaxEdgeShift / 2)` px.
/// - with a `null` [pointer] the card is lifted but flat.
/// - with a [pointer] (card-local) the card leans toward the cursor: the
///   pointer is normalised to `[-1, 1]` from the centre on each axis
///   (clamped), `rotateX = ny * cap`, `rotateY = -nx * cap`. One `cap` serves
///   both axes: the largest angle, up to [kHoverMaxTiltRadians], at which no
///   projected corner moves more than [kHoverMaxEdgeShift] on either axis,
///   scale included (see the derivation in the body). The edge under the
///   cursor recedes; the opposite edge comes toward the viewer.
HoverPose hoverTargetPose({
  required bool hovered,
  required Offset? pointer,
  required Size size,
  required EffectsMode mode,
}) {
  if (mode != EffectsMode.full || !hovered) return HoverPose.rest;
  if (size.isEmpty) {
    return const HoverPose(
      rotateX: 0,
      rotateY: 0,
      scale: kHoverTiltScale,
      lift: 1,
    );
  }
  final half = size.longestSide / 2;
  final growth = math.min(
    (kHoverTiltScale - 1) * half,
    kHoverMaxEdgeShift / 2,
  );
  final scale = 1 + growth / half;
  if (pointer == null) {
    return HoverPose(rotateX: 0, rotateY: 0, scale: scale, lift: 1);
  }
  // Strict bound for corner (±hx, ±hy), L = max(hx, hy), D = hx + hy, scale
  // s and tilt θ on both axes: the corner's depth is at most s·D·θ, so its
  // perspective divisor w ≥ 1 − p·s·D·θ; on screen it sits at most
  // s·L·(1 + θ²)/w from the centre (θ² is rotateX·rotateY's cross term, and
  // θ² ≤ θ·θmax). Keeping that within L + S bounds the corner coming toward
  // the viewer; a receding corner moves less.
  final reach = (size.width + size.height) / 2;
  final cap = math.min(
    kHoverMaxTiltRadians,
    (half + kHoverMaxEdgeShift - scale * half) /
        (scale *
            (half * kHoverMaxTiltRadians +
                (half + kHoverMaxEdgeShift) * kHoverPerspective * reach)),
  );
  final nx = (((pointer.dx / size.width) - 0.5) * 2).clamp(-1.0, 1.0);
  final ny = (((pointer.dy / size.height) - 0.5) * 2).clamp(-1.0, 1.0);
  return HoverPose(
    rotateX: ny * cap,
    rotateY: -nx * cap,
    scale: scale,
    lift: 1,
  );
}

/// The card transform for [pose], applied about the card centre.
///
/// **Contracts**:
/// - [HoverPose.rest] → [Matrix4.identity()], so a resting card's transform
///   takes `RenderTransform`'s translation fast path and adds no layer.
/// - otherwise `identity..setEntry(3, 2, kHoverPerspective)
///   ..rotateX(pose.rotateX)..rotateY(pose.rotateY)` scaled uniformly by
///   `pose.scale` — the perspective is part of every intermediate frame.
Matrix4 hoverTransform(HoverPose pose) {
  if (pose.rotateX == 0 && pose.rotateY == 0 && pose.scale == 1) {
    return Matrix4.identity();
  }
  return Matrix4.identity()
    ..setEntry(3, 2, kHoverPerspective)
    ..rotateX(pose.rotateX)
    ..rotateY(pose.rotateY)
    ..scaleByDouble(pose.scale, pose.scale, pose.scale, 1);
}

/// The glow blur radius for a card with [room] logical px between its edge and
/// the nearest clip edge beside it.
///
/// **Contracts**:
/// - the full [kHoverGlowBlur] whenever it fits.
/// - otherwise the largest blur whose visible reach
///   (`kHoverGlowReachSigmas * sigma`, sigma per
///   [Shadow.convertRadiusToSigma]) plus the card's own movement
///   ([kHoverMaxEdgeShift]) stays within [room], so the glow fades out before
///   the clip instead of being cut.
/// - `0` (no visible glow) when [room] cannot hold even a minimal one.
double hoverGlowBlurFor(double room) {
  final sigma = (room - kHoverMaxEdgeShift) / kHoverGlowReachSigmas;
  // Inverse of Shadow.convertRadiusToSigma: sigma = 0.57735 * radius + 0.5.
  final blur = (sigma - 0.5) / 0.57735;
  return blur.clamp(0.0, kHoverGlowBlur);
}

/// The card decoration at hover progress [lift].
///
/// **Contracts**:
/// - `lift <= 0` → [rest] (same instance).
/// - otherwise [rest] with its border lerped toward [kHoverBorderColor] by
///   [lift] and a single [BoxShadow] glow in [kHoverBorderColor] at
///   `kHoverGlowOpacity * lift` alpha with [glowBlur] blur, so the glow fades
///   in rather than popping; colour and radius preserved.
BoxDecoration hoverDecoration({
  required double lift,
  required BoxDecoration rest,
  double glowBlur = kHoverGlowBlur,
}) {
  if (lift <= 0) return rest;
  return rest.copyWith(
    border: BoxBorder.lerp(
      rest.border,
      Border.all(color: kHoverBorderColor),
      lift,
    ),
    boxShadow: [
      BoxShadow(
        color: kHoverBorderColor.withValues(alpha: kHoverGlowOpacity * lift),
        blurRadius: glowBlur,
      ),
    ],
  );
}
