import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/features/effects/widget/effects_toggle.dart';
import 'package:abigotado_dev/src/features/hero/widget/release_tag.dart';
import 'package:abigotado_dev/src/features/locale/widget/locale_switcher.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// The bottom control bar of the editor shell.
///
/// Desktop layout (`compact: false`): a `Row` with a left cluster (branch
/// name · problem count · [ReleaseTag]) + `Spacer` + right cluster
/// ([LocaleSwitcher] · [EffectsToggle]). Wide enough to avoid overflow.
///
/// Mobile layout (`compact: true`): a `Wrap` containing only [ReleaseTag],
/// [LocaleSwitcher], and [EffectsToggle]. The `Wrap` flows to a second line on
/// narrow widths (320–390 px) and wide locales (e.g. Spanish "Efectos
/// activados"), guaranteeing no `RenderFlex` overflow at any phone width.
/// The 44 px min-height of the switcher buttons sets the individual item
/// height; the bar height grows naturally with the `Wrap` run height.
class EditorStatusBar extends StatelessWidget {
  /// Creates the editor status bar.
  const EditorStatusBar({this.compact = false, super.key});

  /// When `true`, renders the compact mobile layout: a `Wrap` of [ReleaseTag],
  /// [LocaleSwitcher], and [EffectsToggle] — no branch name or problems text.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: compact ? const _CompactBar() : _DesktopBar(l10n: l10n),
    );
  }
}

/// The desktop status-bar body: left text cluster + [Spacer] + right controls.
class _DesktopBar extends StatelessWidget {
  const _DesktopBar({required this.l10n});

  final AppLocalizations l10n;

  static const _monoStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
    color: AppColors.textHint,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 12,
      children: [
        const Text('main', style: _monoStyle),
        Text('✓ ${l10n.problems}', style: _monoStyle),
        const ReleaseTag(),
        const Spacer(),
        const LocaleSwitcher(),
        const EffectsToggle(),
      ],
    );
  }
}

/// The mobile (compact) status-bar body: a [Wrap] that flows controls to a
/// second line on narrow or wide-locale widths. No text labels; [ReleaseTag],
/// [LocaleSwitcher], and [EffectsToggle] only.
class _CompactBar extends StatelessWidget {
  const _CompactBar();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 8,
      runSpacing: 6,
      alignment: WrapAlignment.end,
      children: [ReleaseTag(), LocaleSwitcher(), EffectsToggle()],
    );
  }
}
