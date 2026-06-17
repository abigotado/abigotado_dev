import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Phase of the merge state machine.
///
/// Defined here (alongside its primary consumer, [MergeButton]) and re-used
/// in `MergeCtaSection` to avoid a circular import. A plain enum is correct:
/// this is a domain value that drives a label string, not a widget-factory
/// variant (which would use a sealed class).
enum MergePhase {
  /// Initial state: button is actionable, contacts hidden.
  idle,

  /// Transition: merge animation is playing (full effects mode only).
  merging,

  /// Terminal state: contacts are revealed.
  merged,
}

/// The bespoke green "Merge" button.
///
/// Label varies by [phase] via a `switch` expression (the label differs across
/// phases, not the widget structure — a sealed class would be
/// over-engineering). Below the button a static checks line is always shown.
///
/// Tap target is at least 44 px tall. Pass `null` for [onPressed] when
/// [phase] is [MergePhase.merged] to disable interaction.
class MergeButton extends StatelessWidget {
  /// Creates the merge button.
  const MergeButton({required this.phase, required this.onPressed, super.key});

  /// The current phase of the merge state machine.
  final MergePhase phase;

  /// Called when the button is tapped. Pass `null` when already merged.
  final VoidCallback? onPressed;

  /// The git-style checks line shown below the button — CLI literal, not arb.
  static const String _checksLine =
      'checks passed · reviewer approved · 0 conflicts';

  @override
  Widget build(BuildContext context) {
    final label = switch (phase) {
      MergePhase.idle => '⌥ Merge nikita into your-project/main',
      MergePhase.merging => 'merging…',
      MergePhase.merged => '✓ merged',
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.accentGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              textAlign: TextAlign.center,
              softWrap: true,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.background,
              ),
            ),
          ),
        ),
        const Text(
          _checksLine,
          textAlign: TextAlign.center,
          softWrap: true,
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
