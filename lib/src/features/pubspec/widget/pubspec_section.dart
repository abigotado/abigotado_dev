import 'package:abigotado_dev/src/features/pubspec/widget/pubspec_card.dart';
import 'package:flutter/widgets.dart';

/// The pubspec.yaml skills section — a full-width centred wrapper around
/// [PubspecCard], clamped to 720 px wide with 24 px horizontal padding.
///
/// Mirrors the layout idiom used by MetricsSection:
/// `Center → ConstrainedBox(maxWidth: 720) → Padding(horizontal: 24) →
/// PubspecCard`. The changelog section will sit beside it once delivered;
/// for now it spans the full allowed width.
class PubspecSection extends StatelessWidget {
  /// Creates the pubspec section.
  const PubspecSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: PubspecCard(),
        ),
      ),
    );
  }
}
