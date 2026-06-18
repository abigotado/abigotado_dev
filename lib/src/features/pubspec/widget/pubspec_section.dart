import 'package:abigotado_dev/src/app/widget/content_width.dart';
import 'package:abigotado_dev/src/features/pubspec/widget/pubspec_card.dart';
import 'package:flutter/widgets.dart';

/// The pubspec.yaml skills section — a left-aligned wrapper around
/// [PubspecCard] constrained to `AppSizing.contentMaxWidth` (1000 px) with
/// `AppSizing.contentGutter` (24 px) horizontal padding on each side.
///
/// Uses [ContentWidth] — the same layout token shared by `MetricsSection` and
/// `ChangelogSection` — so all three sections share identical left edges
/// inside the editor pane.
class PubspecSection extends StatelessWidget {
  /// Creates the pubspec section.
  const PubspecSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const ContentWidth(child: PubspecCard());
  }
}
