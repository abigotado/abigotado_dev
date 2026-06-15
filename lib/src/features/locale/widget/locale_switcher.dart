import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/core/locale/supported_locale.dart';
import 'package:abigotado_dev/src/features/locale/state/locale_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A compact row of locale toggle buttons (RU / EN / ES).
///
/// The active segment is highlighted with [AppColors.accentTeal]. Tapping
/// calls [LocaleNotifier.setLocale] — throws at runtime until the notifier
/// is implemented in the GREEN phase (intentional TDD red cycle).
class LocaleSwitcher extends ConsumerWidget {
  /// Creates the locale switcher.
  const LocaleSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch here so the Wrap rebuilds when locale changes.
    ref.watch(localeProvider);

    return Wrap(
      spacing: 4,
      children: SupportedLocale.values
          .map((loc) => _LocaleSegment(loc: loc))
          .toList(),
    );
  }
}

/// A single toggle segment for [LocaleSwitcher].
class _LocaleSegment extends ConsumerWidget {
  const _LocaleSegment({required this.loc});

  final SupportedLocale loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(localeProvider);
    final isActive =
        state.manualChoice == loc ||
        (state.manualChoice == null && state.locale == loc.toLocale());

    return GestureDetector(
      onTap: () => ref.read(localeProvider.notifier).setLocale(loc),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentTeal.withValues(alpha: 0.15) : null,
          border: Border.all(
            color: isActive ? AppColors.accentTeal : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          loc.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? AppColors.accentTeal : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
