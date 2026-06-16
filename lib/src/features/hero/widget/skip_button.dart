import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/features/hero/state/build_scenario_notifier.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The "Skip" escape hatch — jumps the play-out straight to the released
/// snapshot via [BuildScenarioNotifier.skip].
///
/// The view shows this only while effects are full and the scenario is still
/// running; once released there is nothing left to skip. The label comes from
/// arb (`skip`). The tap target is at least 44 px tall for mobile-first UX.
class SkipButton extends ConsumerWidget {
  /// Creates the skip button.
  const SkipButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Align(
      alignment: Alignment.centerRight,
      child: InkWell(
        onTap: () => ref.read(buildScenarioProvider.notifier).skip(),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          alignment: Alignment.center,
          child: Text(
            l10n.skip,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
