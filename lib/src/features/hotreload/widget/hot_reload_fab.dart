import 'package:abigotado_dev/src/app/state/hot_reload_notifier.dart';
import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The floating ⚡ "hot reload" action button.
///
/// A flat amber-glyph circle pinned to the bottom-right of the content pane —
/// the Flutter hot-reload conceit. Tapping it calls `HotReloadNotifier.pulse`,
/// which triggers the section-flash wave in full mode.
///
/// The button is app chrome: it is always present and interactive in BOTH
/// effects modes (only the resulting flash is gated to full mode). A desktop
/// hover brightens its border to amber; the brighten is animated in full mode
/// and instant in lite. The ⚡ glyph is decorative — the accessible affordance
/// is the wrapping [Semantics] button carrying the localized label and hint,
/// with `excludeSemantics: true` so the glyph is never announced on its own.
class HotReloadFab extends ConsumerStatefulWidget {
  /// Creates the hot-reload FAB.
  const HotReloadFab({super.key});

  /// Diameter of the circular button — also its minimum hit-target (≥44 px).
  static const double diameter = 48;

  /// Duration of the hover border-brighten in full mode.
  static const Duration _hoverAnim = Duration(milliseconds: 150);

  @override
  ConsumerState<HotReloadFab> createState() => _HotReloadFabState();
}

class _HotReloadFabState extends ConsumerState<HotReloadFab> {
  bool _hovered = false;

  void _handleTap() => ref.read(hotReloadProvider.notifier).pulse();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mode = effectsModeOf(context, ref);
    final borderColor = _hovered ? AppColors.accentAmber : AppColors.border;

    return Semantics(
      button: true,
      label: l10n.hotreload_label,
      hint: l10n.hotreload_hint,
      onTap: _handleTap,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: _handleTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: mode == EffectsMode.full
                ? HotReloadFab._hoverAnim
                : Duration.zero,
            curve: Curves.easeOut,
            width: HotReloadFab.diameter,
            height: HotReloadFab.diameter,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor),
            ),
            child: const Text(
              '⚡',
              style: TextStyle(
                fontSize: 20,
                height: 1,
                color: AppColors.accentAmber,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
