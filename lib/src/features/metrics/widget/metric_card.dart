import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/app/widget/hover/hover_lift.dart';
import 'package:flutter/material.dart';

/// A single metric card displaying a [label] caption and a prominent [value].
///
/// Used four times by `MetricsSection` to render the key portfolio numbers
/// (app-size reduction, UI responsiveness, monorepo scale, test coverage).
///
/// Layout order matches the mockup: label on top, value below. The
/// [semanticsLabel] is a glyph-free screen-reader announcement that merges
/// both fields into one sentence — the raw [Text] widgets are hidden from
/// accessibility via [ExcludeSemantics] so the reader never vocalises symbols
/// such as `×` (U+00D7), `–` (U+2013), or `→` (U+2192) literally.
class MetricCard extends StatelessWidget {
  /// Creates a metric card.
  const MetricCard({
    required this.value,
    required this.label,
    required this.semanticsLabel,
    super.key,
  });

  /// The prominent metric value shown at the bottom of the card.
  ///
  /// May contain display-only glyphs (×, –, →); use [semanticsLabel] for
  /// screen-reader-safe text.
  final String value;

  /// A short muted caption shown above the value.
  final String label;

  /// Glyph-free screen-reader announcement that describes both [label] and
  /// [value] together (e.g. "app size: from 75 to 40 megabytes").
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: HoverLift(
          restDecoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                value,
                softWrap: true,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
