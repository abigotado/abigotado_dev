import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The first-child chip that opens the `README.md` document.
///
/// Sits outside every landing-page `KeyedSubtree` (see `LandingPage`), above
/// the hero section, so it never shifts any section's measured scroll-spy
/// offset.
///
/// ## Intended GREEN render (implemented in the green pass)
///
/// ```dart
/// ContentWidth(
///   child: Semantics(
///     button: true,
///     child: InkWell(
///       onTap: () => openReadme(context, ref),
///       child: Container(
///         constraints: const BoxConstraints(minHeight: 44),
///         decoration: BoxDecoration(
///           border: Border.all(color: AppColors.border),
///           borderRadius: BorderRadius.circular(6),
///         ),
///         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
///         child: Row(
///           spacing: 8,
///           mainAxisSize: MainAxisSize.min,
///           children: [
///             const Icon(
///               Icons.description_outlined,
///               size: 16,
///               color: AppColors.accentTeal,
///             ),
///             Text(l10n.rm_entry_chip, style: /* monospace, accentTeal */),
///           ],
///         ),
///       ),
///     ),
///   ),
/// )
/// ```
///
/// `openReadme` is the navigation helper in `readme_navigation.dart`. Tap
/// target ≥ 44 px (WCAG 2.5.5), same idiom as `ContactLinkTile` /
/// `EditorFileRow`.
///
/// ## THIS PASS
///
/// `build` returns [SizedBox.shrink] — no chip is rendered until the green
/// pass implements the tree sketched above.
class ReadmeEntryChip extends ConsumerWidget {
  /// Creates the README entry chip.
  const ReadmeEntryChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const SizedBox.shrink();
}
