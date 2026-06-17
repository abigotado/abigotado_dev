import 'package:abigotado_dev/src/features/metrics/metrics_layout.dart';
import 'package:abigotado_dev/src/features/metrics/widget/metric_card.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// The portfolio-metrics section: four cards showing key engineering results.
///
/// The four metrics are taken directly from the approved mockup:
///   - App size: 75 → 40 MB
///   - UI responsiveness: ×3–5
///   - Monorepo: 100+ packages
///   - Test coverage: 70–75%
///
/// Layout is responsive via [metricsColumnsFor]: 1–4 columns depending on the
/// available width after the 720px clamp and 24px horizontal padding.
///
/// The section is always visible — it has no Riverpod dependency and requires
/// no provider gating.
class MetricsSection extends StatelessWidget {
  /// Creates the metrics section.
  const MetricsSection({super.key});

  /// Speed multiplier displayed on the UI-responsiveness card (sighted only).
  /// U+00D7 × and U+2013 – per the approved codepoint list.
  static const String _speedValue = '×3–5';

  /// Coverage range displayed on the test-coverage card (sighted only).
  /// U+2013 – per the approved codepoint list.
  static const String _coverageValue = '70–75%';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // The four card data records; built inline — no Widget _buildX() helper.
    final cards = [
      (
        value: '75 → 40 ${l10n.mb}',
        label: l10n.m1,
        semanticsLabel: l10n.m1_a11y,
      ),
      (
        value: _speedValue,
        label: l10n.m2,
        semanticsLabel: l10n.m2_a11y,
      ),
      (
        value: l10n.m3v,
        label: l10n.m3,
        semanticsLabel: l10n.m3_a11y,
      ),
      (
        value: _coverageValue,
        label: l10n.m4,
        semanticsLabel: l10n.m4_a11y,
      ),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final available = constraints.maxWidth;
              final columns = metricsColumnsFor(available);
              const gap = 12.0;
              final cardWidth = (available - gap * (columns - 1)) / columns;

              return Wrap(
                spacing: gap,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  for (final card in cards)
                    SizedBox(
                      width: cardWidth,
                      child: MetricCard(
                        value: card.value,
                        label: card.label,
                        semanticsLabel: card.semanticsLabel,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
