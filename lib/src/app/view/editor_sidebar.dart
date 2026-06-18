import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/app/theme/app_sizing.dart';
import 'package:abigotado_dev/src/app/widget/editor_file.dart';
import 'package:abigotado_dev/src/app/widget/editor_file_row.dart';
import 'package:flutter/material.dart';

/// The fixed-width file-explorer sidebar shown alongside the editor pane.
///
/// Displays an `EXPLORER` header, a root `▾ abigotado.dev` row, and one
/// [EditorFileRow] per [EditorFile] value. The panel has a slightly darker
/// background than the page and a right hairline border.
class EditorSidebar extends StatelessWidget {
  /// Creates the editor sidebar.
  const EditorSidebar({super.key});

  static const _headerStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textHint,
    letterSpacing: 0.8,
  );

  static const _rootStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    color: AppColors.textMuted,
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSizing.sidebarWidth,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            right: BorderSide(color: AppColors.border),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 12, 8, 4),
              child: Text('EXPLORER', style: _headerStyle),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: Text('▾ abigotado.dev', style: _rootStyle),
            ),
            ...EditorFile.values.map((f) => EditorFileRow(file: f)),
          ],
        ),
      ),
    );
  }
}
