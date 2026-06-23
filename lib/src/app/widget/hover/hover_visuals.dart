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

/// Fixed perspective-tilt angle applied in full mode while hovered.
///
/// Approximately 2 degrees. The tilt is always in the same direction — it is
/// NOT cursor-tracked — so the effect is a subtle lift cue rather than a
/// parallax. Cursor-tracking would require access to the pointer position in
/// every build, adding unnecessary coupling to mouse state.
const double kHoverTiltRadians = 0.035;

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

/// Returns a [Matrix4] transform that applies a subtle fixed-direction
/// perspective tilt while hovered in full mode.
///
/// In [EffectsMode.full] **and** [hovered] the transform combines:
/// - A perspective projection (entry [3][2] = 0.001).
/// - An X-axis rotation of [kHoverTiltRadians].
/// - A Y-axis rotation of `-kHoverTiltRadians`.
/// - A uniform scale of [kHoverTiltScale].
///
/// The tilt is always in the same fixed direction — it is NOT cursor-tracked —
/// so the effect is a subtle lift cue rather than a parallax. Cursor-tracking
/// would require access to the pointer position in every build, adding
/// unnecessary coupling to mouse state.
///
/// In [EffectsMode.lite] **or** `!hovered` [Matrix4.identity()] is returned so
/// the card is painted untransformed (the tilt is a no-op).
///
/// **Contracts (green pass)**:
/// - `full + hovered` → returned matrix is not identity.
/// - `lite + hovered` → [Matrix4.identity()] (no transform).
/// - `full + !hovered` → [Matrix4.identity()] (no transform).
Matrix4 hoverTilt({required bool hovered, required EffectsMode mode}) {
  return switch ((mode, hovered)) {
    (EffectsMode.full, true) =>
      Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(kHoverTiltRadians)
        ..rotateY(-kHoverTiltRadians)
        ..scaleByDouble(kHoverTiltScale, kHoverTiltScale, kHoverTiltScale, 1),
    _ => Matrix4.identity(),
  };
}
