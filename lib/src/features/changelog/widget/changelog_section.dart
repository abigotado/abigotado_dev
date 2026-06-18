import 'package:abigotado_dev/src/app/widget/content_width.dart';
import 'package:abigotado_dev/src/features/changelog/widget/changelog_card.dart';
import 'package:flutter/widgets.dart';

/// The CHANGELOG.md career-timeline section — a left-aligned wrapper around
/// [ChangelogCard] constrained to `AppSizing.contentMaxWidth` (1000 px) with
/// `AppSizing.contentGutter` (24 px) horizontal padding on each side.
///
/// Uses [ContentWidth] — the same layout token shared by `MetricsSection` and
/// `PubspecSection` — so all three sections share identical left edges inside
/// the editor pane.
class ChangelogSection extends StatelessWidget {
  /// Creates the changelog section.
  const ChangelogSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const ContentWidth(child: ChangelogCard());
  }
}
