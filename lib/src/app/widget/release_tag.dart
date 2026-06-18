import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:flutter/widgets.dart';

/// A small green pill badge showing the literal `RELEASE`.
///
/// This widget is intentionally **static** — it does not read
/// `buildScenarioProvider`. The live phase tie-in (showing `DEBUG` until the
/// scenario reaches `released`) is a later increment.
class ReleaseTag extends StatelessWidget {
  /// Creates the release tag badge.
  const ReleaseTag({super.key});

  static const _labelStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.accentGreen,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accentGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text('RELEASE', style: _labelStyle),
    );
  }
}
