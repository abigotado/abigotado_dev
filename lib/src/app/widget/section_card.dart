import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/app/widget/hover/hover_lift.dart';
import 'package:abigotado_dev/src/app/widget/reveal/type_on_heading.dart';
import 'package:flutter/widgets.dart';

/// Shared chrome for the file-card sections (pubspec.yaml, CHANGELOG.md).
///
/// Renders a container with a surface background, hairline border, and rounded
/// corners. Inside: a header [Row] with the invariant filename [title] on the
/// left and the localized [badge] on the right, a hairline divider, then the
/// [child].
///
/// **Accessibility:** [SectionCard] is intentionally a11y-neutral — it owns no
/// [Semantics], [MergeSemantics], or [ExcludeSemantics] nodes. Each consumer
/// wraps the card in whatever semantics are appropriate for its content:
/// - `PubspecCard` wraps in `Semantics(container: true, label: ...) →
///   ExcludeSemantics` because the code body is decorative.
/// - `ChangelogCard` needs no wrapper because the content is readable prose.
class SectionCard extends StatelessWidget {
  /// Creates the shared file-card chrome.
  ///
  /// [title] is the invariant filename literal (e.g. `'pubspec.yaml'`,
  /// `'CHANGELOG.md'`). [badge] is a localized label resolved by the caller.
  /// [child] is the section-specific content area.
  const SectionCard({
    required this.title,
    required this.badge,
    required this.child,
    super.key,
  });

  /// The invariant filename string shown on the left of the card header.
  final String title;

  /// The localized badge shown on the right of the card header.
  final String badge;

  /// The section-specific content placed below the hairline divider.
  final Widget child;

  // Monospace style shared by both header texts.
  static const _headerMono = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    color: AppColors.textMuted,
  );

  @override
  Widget build(BuildContext context) {
    return HoverLift(
      restDecoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          // Header row: filename (left) + localized badge (right).
          // Both wrapped in Flexible so the row never overflows on narrow
          // viewports (e.g. 320 px).
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: TypeOnHeading(
                  text: title,
                  style: _headerMono,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: Text(
                  badge,
                  overflow: TextOverflow.ellipsis,
                  style: _headerMono,
                ),
              ),
            ],
          ),
          // Hairline divider between header and content.
          Container(
            height: 1,
            color: AppColors.border,
          ),
          child,
        ],
      ),
    );
  }
}
