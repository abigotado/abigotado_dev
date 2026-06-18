import 'package:abigotado_dev/src/app/state/scroll_spy_notifier.dart';
import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/app/theme/app_sizing.dart';
import 'package:abigotado_dev/src/app/widget/editor_file.dart';
import 'package:abigotado_dev/src/app/widget/editor_file_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The fixed-width file-explorer sidebar shown alongside the editor pane.
///
/// Displays an `EXPLORER` header, a root `▾ abigotado.dev` row, and one
/// [EditorFileRow] per [EditorFile] value. The panel has a slightly darker
/// background than the page and a right hairline border.
///
/// The EXPLORER header and root row are fixed; the file rows are wrapped in
/// a [SingleChildScrollView] bounded by [Expanded] so a short window scrolls
/// the list rather than overflowing vertically.
///
/// Watches [activeEditorFileValueProvider] to highlight the active row and
/// dispatches [ScrollSpyNotifier.requestScrollTo] on tap.
class EditorSidebar extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeEditorFileValueProvider);

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
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final f in EditorFile.values)
                      EditorFileRow(
                        file: f,
                        selected: f == active,
                        onTap: () => ref
                            .read(scrollSpyProvider.notifier)
                            .requestScrollTo(f),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
