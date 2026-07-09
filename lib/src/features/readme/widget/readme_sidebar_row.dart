import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/features/readme/state/presentation_notifier.dart';
import 'package:abigotado_dev/src/features/readme/view/readme_navigation.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The sidebar row for `README.md`, appended below the `EditorFile` loop.
///
/// Deliberately its OWN widget — NOT `EditorFileRow`, and NOT a 6th
/// `EditorFile` value. `EditorFile` models the pitch's five scroll-spy
/// sections; `README.md` is a different presentation entirely (it replaces
/// the pane, it isn't a section within it), so folding it into `EditorFile`
/// would corrupt every "exactly one selected row" assumption the scroll-spy
/// tests make about that enum. This widget renders alongside the
/// `EditorFileRow` list but is driven by [readmeOpenProvider], not
/// `activeEditorFileValueProvider`.
///
/// Mirrors `EditorFileRow`'s visual chrome exactly (icon + monospace filename
/// + hint-colored decode label, ≥ 44 px tap target, `Semantics(selected:
/// ...)`) but is its own class so the sidebar can special-case its selection
/// logic without touching `EditorFileRow`'s contract.
class ReadmeSidebarRow extends ConsumerWidget {
  /// Creates the README sidebar row.
  const ReadmeSidebarRow({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(readmeOpenProvider);

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: () => openReadme(context, ref),
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
                  Icons.menu_book_outlined,
                  size: 14,
                  color: selected ? AppColors.accentTeal : AppColors.textHint,
                ),
                Expanded(
                  child: Text(
                    'README.md',
                    style: selected ? _rowMonoSelected : _rowMono,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(l10n.file_readme, style: _labelStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
