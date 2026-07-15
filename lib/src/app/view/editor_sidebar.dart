import 'dart:async';

import 'package:abigotado_dev/src/app/state/scroll_spy_notifier.dart';
import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/app/theme/app_sizing.dart';
import 'package:abigotado_dev/src/app/widget/editor_file.dart';
import 'package:abigotado_dev/src/app/widget/editor_file_row.dart';
import 'package:abigotado_dev/src/features/readme/state/presentation_notifier.dart';
import 'package:abigotado_dev/src/features/readme/widget/readme_sidebar_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The fixed-width file-explorer sidebar shown alongside the editor pane.
///
/// Displays an `EXPLORER` header, a root `▾ abigotado.dev` row, one
/// [EditorFileRow] per [EditorFile] value, and a [ReadmeSidebarRow] below
/// them. The panel has a slightly darker background than the page and a
/// right hairline border.
///
/// The EXPLORER header and root row are fixed; the file rows are wrapped in
/// a [SingleChildScrollView] bounded by [Expanded] so a short window scrolls
/// the list rather than overflowing vertically.
///
/// Watches [activeEditorFileValueProvider] to highlight the active row and
/// dispatches [ScrollSpyNotifier.requestScrollTo] on tap. While the README is
/// open ([readmeOpenProvider]), no [EditorFileRow] is selected — tapping one
/// closes the README (via `Navigator.maybePop`, popping the local history
/// entry armed by `openReadme`) and then requests the scroll target for the
/// return-to-pitch landing.
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
    final readmeOpen = ref.watch(readmeOpenProvider);

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
                        selected: !readmeOpen && f == active,
                        onTap: () {
                          // No-op on the default pitch path (nothing to pop,
                          // Navigator.maybePop resolves false with no side
                          // effect); pops the README's local history entry
                          // when it is open, in lockstep with showPitch.
                          unawaited(Navigator.of(context).maybePop());
                          ref
                              .read(scrollSpyProvider.notifier)
                              .requestScrollTo(f);
                        },
                      ),
                    const ReadmeSidebarRow(),
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
