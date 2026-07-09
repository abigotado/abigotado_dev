import 'package:abigotado_dev/src/features/readme/state/presentation_notifier.dart';
import 'package:flutter/widgets.dart';
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
/// ## Intended GREEN render (implemented in the green pass)
///
/// ```dart
/// EditorFileRow-style row:
///   filename: 'README.md'
///   decode label: l10n.file_readme
///   selected: ref.watch(readmeOpenProvider)
///   onTap: () => openReadme(context, ref)
/// ```
///
/// Mirrors `EditorFileRow`'s visual chrome exactly (icon + monospace filename
/// + hint-colored decode label, ≥ 44 px tap target, `Semantics(selected:
/// ...)`) but is its own class so the sidebar can special-case its selection
/// logic without touching `EditorFileRow`'s contract.
///
/// ## THIS PASS
///
/// `build` returns [SizedBox.shrink] — no row is rendered until the green
/// pass implements the tree sketched above.
class ReadmeSidebarRow extends ConsumerWidget {
  /// Creates the README sidebar row.
  const ReadmeSidebarRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const SizedBox.shrink();
}
