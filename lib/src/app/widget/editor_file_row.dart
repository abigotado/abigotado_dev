import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/app/widget/editor_file.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// A single row in the editor sidebar file-explorer panel.
///
/// Shows the file's [EditorFile.icon] (muted, ~14 px), its
/// [EditorFile.filename] in monospace, and the localized clarity decode-label
/// right-aligned in hint color at a smaller size.
///
/// [selected] tints the row with a subtle IDE-style active-file highlight and
/// exposes `isSelected` via [Semantics] so assistive technology can report
/// which file is currently in view.
/// [onTap] navigates to the section when the user taps the row.
class EditorFileRow extends StatelessWidget {
  /// Creates a sidebar file row for [file].
  const EditorFileRow({
    required this.file,
    required this.selected,
    this.onTap,
    super.key,
  });

  /// The file this row represents.
  final EditorFile file;

  /// Whether this row represents the currently active (in-view) section.
  final bool selected;

  /// Called when the user taps the row to navigate to this section.
  final VoidCallback? onTap;

  static const _rowMono = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    color: AppColors.textMuted,
  );

  static const _rowMonoSelected = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    color: AppColors.textPrimary,
  );

  static const _labelStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 11,
    color: AppColors.textHint,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            color: selected
                ? AppColors.accentTeal.withValues(alpha: 0.10)
                : null,
            child: Row(
              spacing: 6,
              children: [
                Icon(
                  file.icon,
                  size: 14,
                  color: selected ? AppColors.accentTeal : AppColors.textHint,
                ),
                Expanded(
                  child: Text(
                    file.filename,
                    style: selected ? _rowMonoSelected : _rowMono,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(file.label(l10n), style: _labelStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
