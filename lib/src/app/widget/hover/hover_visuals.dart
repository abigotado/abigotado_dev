import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:flutter/material.dart';

/// Duration in milliseconds for the hover enter/exit transition.
const int kHoverAnimMs = 160;

/// Border color applied to a card's decoration while hovered in full mode.
const Color kHoverBorderColor = AppColors.accentPurple;

/// Blur radius (logical pixels) for the glow box-shadow added on hover.
const double kHoverGlowBlur = 24;

/// Opacity of the glow box-shadow added on hover.
const double kHoverGlowOpacity = 0.33;

/// Maximum perspective-tilt angle (radians) reached at a card's edges while
/// hovered in full mode.
///
/// Approximately 3.5 degrees. The tilt is cursor-tracked: the angle on each
/// axis scales with the pointer's distance from the card centre — zero at the
/// centre, this value at the edge — so the card leans toward the cursor.
const double kHoverMaxTiltRadians = 0.06;

/// Scale factor applied together with the tilt while hovered in full mode.
const double kHoverTiltScale = 1.02;

/// Returns the [BoxDecoration] to use for [rest] given the current hover and
/// effects state.
///
/// In [EffectsMode.full] **and** [hovered] the returned decoration is
/// `rest.copyWith` with:
/// - [Border.all] using [kHoverBorderColor] (replaces the muted resting
///   border).
/// - A single [BoxShadow] using [kHoverBorderColor] at [kHoverGlowOpacity] and
///   [kHoverGlowBlur] (the accent glow).
///
/// In [EffectsMode.lite] **or** `!hovered` [rest] is returned unchanged so the
/// card is always static under reduced-motion.
///
/// **Contracts (green pass)**:
/// - `full + hovered` → decoration differs from [rest]: border colour is
///   [kHoverBorderColor] and `boxShadow` is non-null, non-empty.
/// - `lite + hovered` → returns [rest] unchanged (same object identity).
/// - `full + !hovered` → returns [rest] unchanged (same object identity).
BoxDecoration hoverDecoration({
  required bool hovered,
  required EffectsMode mode,
  required BoxDecoration rest,
}) {
  return switch ((mode, hovered)) {
    (EffectsMode.full, true) => rest.copyWith(
      border: Border.all(color: kHoverBorderColor),
      boxShadow: [
        BoxShadow(
          color: kHoverBorderColor.withValues(alpha: kHoverGlowOpacity),
          blurRadius: kHoverGlowBlur,
        ),
      ],
    ),
    _ => rest,
  };
}

/// Returns a [Matrix4] transform for the hover lift while hovered in full mode.
///
/// In [EffectsMode.full] **and** [hovered] the card is scaled by
/// [kHoverTiltScale] under a perspective projection (entry [3][2] = 0.001) and
/// tilted toward the cursor: [pointer] is the cursor position in the card's
/// local coordinates and [size] its laid-out size, so the X/Y rotation on each
/// axis grows with the pointer's distance from the centre, up to
/// [kHoverMaxTiltRadians] at the edges. When [pointer] is `null` (the hover has
/// just begun, before the first move) or [size] is empty the card is scaled but
/// flat — the parallax kicks in on the first pointer move.
///
/// In [EffectsMode.lite] **or** `!hovered` [Matrix4.identity()] is returned so
/// the card is painted untransformed (the tilt is a no-op).
///
/// **Contracts**:
/// - `full + hovered` → returned matrix is not identity (at minimum the scale).
/// - `full + hovered`, pointer off-centre → tilt differs from the centred one.
/// - `lite + hovered` → [Matrix4.identity()] (no transform).
/// - `full + !hovered` → [Matrix4.identity()] (no transform).
Matrix4 hoverTilt({
  required bool hovered,
  required Offset? pointer,
  required Size size,
  required EffectsMode mode,
}) {
  if (mode != EffectsMode.full || !hovered) return Matrix4.identity();

  final transform = Matrix4.identity()..setEntry(3, 2, 0.001);

  if (pointer != null && size.width > 0 && size.height > 0) {
    // Normalise the pointer to [-1, 1] from the card centre, clamped so an
    // event landing on the very edge can't over-rotate past the max angle.
    final nx = (((pointer.dx / size.width) - 0.5) * 2).clamp(-1.0, 1.0);
    final ny = (((pointer.dy / size.height) - 0.5) * 2).clamp(-1.0, 1.0);
    transform
      ..rotateX(ny * kHoverMaxTiltRadians)
      ..rotateY(-nx * kHoverMaxTiltRadians);
  }

  return transform
    ..scaleByDouble(kHoverTiltScale, kHoverTiltScale, kHoverTiltScale, 1);
}
