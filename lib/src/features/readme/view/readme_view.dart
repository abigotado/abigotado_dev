import 'dart:async';

import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/app/theme/app_sizing.dart';
import 'package:abigotado_dev/src/app/widget/content_width.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/features/readme/view/readme_body.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The `README.md` document view — the pane's alternate presentation to the
/// stylized pitch, opened via `PresentationView.readme`.
///
/// Owns a [ScrollController] and one [GlobalKey] per [ReadmeAnchor], mirroring
/// `EditorScrollHost`'s ownership pattern. Static: unlike the pitch's
/// scroll-spy, the anchor bar has no "currently active" highlight logic in
/// stage 1 — it is a pure jump-to-section control.
class ReadmeView extends ConsumerStatefulWidget {
  /// Creates the README document view.
  const ReadmeView({super.key});

  @override
  ConsumerState<ReadmeView> createState() => _ReadmeViewState();
}

class _ReadmeViewState extends ConsumerState<ReadmeView> {
  final ScrollController _controller = ScrollController();

  /// One [GlobalKey] per [ReadmeAnchor], used by the anchor bar to locate
  /// section positions for `Scrollable.ensureVisible`.
  final Map<ReadmeAnchor, GlobalKey> _sectionKeys = {
    for (final a in ReadmeAnchor.values) a: GlobalKey(),
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Scrolls [anchor]'s section into view.
  ///
  /// Lite mode uses [Duration.zero] so `ensureVisible` calls `jumpTo`
  /// internally — no animation ticker is scheduled (mirrors
  /// `EditorScrollHost._onScrollRequest`'s FIX-3 reduced-motion asymmetry).
  void _jumpTo(ReadmeAnchor anchor, EffectsMode mode) {
    final ctx = _sectionKeys[anchor]?.currentContext;
    if (ctx == null) return;

    unawaited(
      Scrollable.ensureVisible(
        ctx,
        duration: mode == EffectsMode.lite
            ? Duration.zero
            : const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mode = effectsModeOf(context, ref);

    return Column(
      // Stretch, not the default centre: the tab and anchor-bar strips span
      // the full pane width (their bottom borders read as toolbar rules) and
      // the anchor chips left-align with the document below.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReadmeTab(
          title: l10n.rm_tab_title,
          closeHint: l10n.rm_close_hint,
          onClose: () => Navigator.of(context).maybePop(),
        ),
        _ReadmeAnchorBar(
          l10n: l10n,
          onJump: (anchor) => _jumpTo(anchor, mode),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _controller,
            child: ContentWidth(
              maxWidth: AppSizing.readmeMaxWidth,
              child: ReadmeBody(sectionKeys: _sectionKeys),
            ),
          ),
        ),
      ],
    );
  }
}

/// The `README.md` tab row: the invariant filename title plus a ✕ close
/// control.
class _ReadmeTab extends StatelessWidget {
  const _ReadmeTab({
    required this.title,
    required this.closeHint,
    required this.onClose,
  });

  final String title;
  final String closeHint;
  final VoidCallback onClose;

  static const _titleStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    color: AppColors.textPrimary,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: _titleStyle),
          Semantics(
            button: true,
            label: closeHint,
            excludeSemantics: true,
            onTap: onClose,
            child: InkWell(
              onTap: onClose,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                child: const Center(
                  child: Text(
                    '✕',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The anchor bar: a [Wrap] of 4 chips, one per [ReadmeAnchor], jumping to
/// the corresponding section via [onJump].
class _ReadmeAnchorBar extends StatelessWidget {
  const _ReadmeAnchorBar({required this.l10n, required this.onJump});

  final AppLocalizations l10n;
  final ValueChanged<ReadmeAnchor> onJump;

  String _labelFor(ReadmeAnchor anchor) => switch (anchor) {
    ReadmeAnchor.experience => l10n.rm_anchor_experience,
    ReadmeAnchor.skills => l10n.rm_anchor_skills,
    ReadmeAnchor.education => l10n.rm_anchor_education,
    ReadmeAnchor.contacts => l10n.rm_anchor_contacts,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final anchor in ReadmeAnchor.values)
            _ReadmeAnchorChip(
              label: _labelFor(anchor),
              onTap: () => onJump(anchor),
            ),
        ],
      ),
    );
  }
}

/// One anchor-bar chip — a bordered, tappable jump-to-section control.
///
/// Each anchor label (e.g. `l10n.rm_anchor_skills` = "Skills") is the SAME
/// localized string as the section heading it jumps to
/// (`l10n.rm_h_skills` = "Skills"): a natural nav-word/heading-word echo.
/// The chip is the only [InkWell]-wrapped bearer of that word, so tests
/// address it via `find.widgetWithText(InkWell, …)`.
class _ReadmeAnchorChip extends StatelessWidget {
  const _ReadmeAnchorChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(6),
          ),
          // Center(widthFactor: 1) keeps the label vertically centred within
          // the 44 px min-height box while the chip shrink-wraps its width.
          // Container(alignment:) would instead expand to the Wrap's full run
          // width, stacking the four chips into full-width rows.
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: AppColors.accentTeal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
