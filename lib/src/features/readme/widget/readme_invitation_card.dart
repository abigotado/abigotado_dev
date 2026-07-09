import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The closing invitation card that opens the `README.md` document.
///
/// Sits after the contacts `KeyedSubtree` and before `LandingPage`'s FAB
/// clearance `SizedBox`, outside every `KeyedSubtree` — same rationale as
/// `ReadmeEntryChip`: it must never shift a section's measured scroll-spy
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
///           color: AppColors.surface,
///           border: Border.all(color: AppColors.border),
///           borderRadius: BorderRadius.circular(8),
///         ),
///         padding: const EdgeInsets.all(16),
///         child: Text(l10n.rm_invitation, style: /* textMuted, 14 */),
///       ),
///     ),
///   ),
/// )
/// ```
///
/// Same `onTap` target as `ReadmeEntryChip` — both funnel through the single
/// `openReadme` helper. Tap target ≥ 44 px (WCAG 2.5.5).
///
/// ## THIS PASS
///
/// `build` returns [SizedBox.shrink] — no card is rendered until the green
/// pass implements the tree sketched above.
class ReadmeInvitationCard extends ConsumerWidget {
  /// Creates the README invitation card.
  const ReadmeInvitationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const SizedBox.shrink();
}
