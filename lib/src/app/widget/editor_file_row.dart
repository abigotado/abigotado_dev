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
/// Selection state is not modelled in increment 1.
class EditorFileRow extends StatelessWidget {
  /// Creates a sidebar file row for [file].
  const EditorFileRow({required this.file, super.key});

  /// The file this row represents.
  final EditorFile file;

  static const _rowMono = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    color: AppColors.textMuted,
  );

  static const _labelStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 11,
    color: AppColors.textHint,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Row(
        children: [
          Icon(file.icon, size: 14, color: AppColors.textHint),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              file.filename,
              style: _rowMono,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(file.label(l10n), style: _labelStyle),
        ],
      ),
    );
  }
}
