import 'package:flutter/widgets.dart';

/// Brand color tokens for abigotado.dev.
///
/// The palette is the single source of truth shared by the theme and the
/// hand-tuned section visuals. Values mirror the approved mockup
/// (`CV/landing/mockup_v1.html`). Dark surface by design — this is a
/// terminal-flavored site.
abstract final class AppColors {
  /// Page background — the darkest surface.
  static const Color background = Color(0xFF0F1115);

  /// Raised surface (cards, terminal, panels).
  static const Color surface = Color(0xFF171A21);

  /// Slightly lighter raised surface (floating controls).
  static const Color surfaceElevated = Color(0xFF1E222B);

  /// Hairline borders between surfaces.
  static const Color border = Color(0xFF2A2F3A);

  /// Primary text on dark surfaces.
  static const Color textPrimary = Color(0xFFE8EAF0);

  /// Secondary, muted text.
  static const Color textMuted = Color(0xFF9AA3B2);

  /// Tertiary hint text (terminal comments, captions).
  static const Color textHint = Color(0xFF6B7280);

  /// Accent — agents / structural highlights.
  static const Color accentPurple = Color(0xFF8B80F9);

  /// Accent — success, "done", primary actions.
  static const Color accentTeal = Color(0xFF2DD4A7);

  /// Accent — work in progress, values, warnings.
  static const Color accentAmber = Color(0xFFF0A32F);

  /// Accent — debug / error states.
  static const Color accentRed = Color(0xFFEF5350);

  /// Accent — release / merge / shipped.
  static const Color accentGreen = Color(0xFF34C98E);
}
