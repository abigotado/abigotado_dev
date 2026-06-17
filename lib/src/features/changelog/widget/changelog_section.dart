import 'package:abigotado_dev/src/features/changelog/widget/changelog_card.dart';
import 'package:flutter/widgets.dart';

/// The CHANGELOG.md career-timeline section — a full-width centred wrapper
/// around [ChangelogCard], clamped to 720 px wide with 24 px horizontal
/// padding.
///
/// Mirrors the layout idiom used by the pubspec section:
/// `Center → ConstrainedBox(maxWidth: 720) → Padding(horizontal: 24) →
/// ChangelogCard`.
class ChangelogSection extends StatelessWidget {
  /// Creates the changelog section.
  const ChangelogSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: ChangelogCard(),
        ),
      ),
    );
  }
}
