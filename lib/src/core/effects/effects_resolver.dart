import 'package:abigotado_dev/src/core/effects/effects_mode.dart';

/// Resolves the effective [EffectsMode] from the available signals, in
/// priority order:
///
/// 1. [manualChoice] — an explicit user preference always wins.
/// 2. OS-level reduced-motion flag ([osReducedMotion]) or a compact/mobile
///    viewport ([isCompact]) → [EffectsMode.lite].
/// 3. [EffectsMode.full] — default for desktop without reduced-motion.
///
/// Pure function — no side effects, no I/O. Unit-testable without a widget.
EffectsMode resolveEffectsMode({
  required bool osReducedMotion,
  required bool isCompact,
  EffectsMode? manualChoice,
}) {
  if (manualChoice != null) return manualChoice;
  if (osReducedMotion || isCompact) return EffectsMode.lite;
  return EffectsMode.full;
}
