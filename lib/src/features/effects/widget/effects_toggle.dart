import 'dart:async';

import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A compact toggle button that shows the current effects mode and lets the
/// user flip between [EffectsMode.full] and [EffectsMode.lite].
///
/// The effective mode is resolved via [effectsModeOf], which factors in the
/// manual choice, the OS reduced-motion preference, and the viewport width.
/// Tapping toggles between the two modes by calling [EffectsNotifier.setMode].
class EffectsToggle extends ConsumerWidget {
  /// Creates the effects toggle.
  const EffectsToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = effectsModeOf(context, ref);
    final isOn = mode == EffectsMode.full;

    return Tooltip(
      message: l10n.effects_hint,
      child: InkWell(
        onTap: () {
          final next = isOn ? EffectsMode.lite : EffectsMode.full;
          unawaited(ref.read(effectsProvider.notifier).setMode(next));
        },
        borderRadius: BorderRadius.circular(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          // Ensure a minimum ~44 px tall tap target for mobile-first UX.
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isOn ? AppColors.accentAmber.withValues(alpha: 0.15) : null,
            border: Border.all(
              color: isOn ? AppColors.accentAmber : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(
              isOn ? l10n.effects_on : l10n.effects_off,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isOn ? AppColors.accentAmber : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
