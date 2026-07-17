import 'dart:math' as math;

import 'package:abigotado_dev/src/app/widget/content_width.dart';
import 'package:abigotado_dev/src/app/widget/reveal/build_cascade_item.dart';
import 'package:abigotado_dev/src/features/metrics/metrics_layout.dart';
import 'package:abigotado_dev/src/features/metrics/widget/metric_card.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// The portfolio-metrics section: three cards showing key engineering results.
///
/// The three metrics come straight from the résumé — the single source of truth
/// for every figure on this page (CONCEPT rule: numbers must match the résumé):
///   - UI responsiveness: ×3–5 (Somnio)
///   - Test coverage: 70–75% (RZD)
///   - Downloads: 10K+ across app stores (FinHarbor, Digital Technologies)
///
/// Layout is responsive via [metricsColumnsFor]: 1–4 columns depending on the
/// available width after the `AppSizing.contentMaxWidth` (1000 px) cap and
/// `AppSizing.contentGutter` (24 px) horizontal padding on each side. The
/// column count is additionally capped at the card count so the three cards
/// fill the row evenly rather than leaving an empty fourth column on a wide
/// desktop.
///
/// The section is always visible — it has no Riverpod dependency and requires
/// no provider gating.
///
/// Each card is wrapped in a `BuildCascadeItem` keyed by its position among
/// the three cards, so — while beneath an in-progress `RevealBuild` — the
/// cards fade/slide in one by one. Outside a build in progress,
/// `BuildCascadeItem` is a no-op passthrough and this section's render is
/// unchanged.
class MetricsSection extends StatelessWidget {
  /// Creates the metrics section.
  const MetricsSection({super.key});

  /// Speed multiplier displayed on the UI-responsiveness card (sighted only).
  /// U+00D7 × and U+2013 – per the approved codepoint list.
  static const String _speedValue = '×3–5';

  /// Coverage range displayed on the test-coverage card (sighted only).
  /// U+2013 – per the approved codepoint list.
  static const String _coverageValue = '70–75%';

  /// Downloads figure displayed on the downloads card (sighted only).
  /// ASCII-only ("10K+") — no special glyphs, identical across locales, so it
  /// is a const here (like [_speedValue]/[_coverageValue]) rather than an arb
  /// value; only the localized label and screen-reader text live in arb.
  static const String _downloadsValue = '10K+';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // The three card data records; built inline — no Widget _buildX() helper.
    final cards = [
      (
        value: _speedValue,
        label: l10n.m2,
        semanticsLabel: l10n.m2_a11y,
      ),
      (
        value: _coverageValue,
        label: l10n.m4,
        semanticsLabel: l10n.m4_a11y,
      ),
      (
        value: _downloadsValue,
        label: l10n.m_dl,
        semanticsLabel: l10n.m_dl_a11y,
      ),
    ];

    return ContentWidth(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxWidth;
          // Cap columns at the card count so three cards fill the row evenly
          // instead of leaving an empty fourth column on a wide desktop.
          final columns = math.min(metricsColumnsFor(available), cards.length);
          const gap = 12.0;
          final cardWidth = (available - gap * (columns - 1)) / columns;

          return Wrap(
            spacing: gap,
            runSpacing: 12,
            children: [
              for (final (i, card) in cards.indexed)
                BuildCascadeItem(
                  index: i,
                  count: cards.length,
                  child: SizedBox(
                    width: cardWidth,
                    child: MetricCard(
                      value: card.value,
                      label: card.label,
                      semanticsLabel: card.semanticsLabel,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
