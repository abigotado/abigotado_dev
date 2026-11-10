/// Pure layout helpers for the metrics section grid.
library;

import 'dart:math' as math;

/// Horizontal gap between metric cards in one row, in logical pixels.
const double metricsGap = 12;

/// Number of metric-card columns for the width AVAILABLE to the grid — i.e. the
/// `LayoutBuilder`-local `maxWidth`, already net of the section's horizontal
/// padding (the LayoutBuilder sits inside both the `AppSizing.contentMaxWidth`
/// (1000px) clamp and the `AppSizing.contentGutter` (24px) padding, so this
/// width is post-clamp and post-padding).
///
/// Reproduces the mockup's CSS `repeat(auto-fit, minmax(160px, 1fr))`: a new
/// column appears only once every card can stay >=160px wide given the 12px
/// inter-card gaps. Thresholds: 1 col < 332 <= 2 col < 504 <= 3 col < 676 <= 4.
/// Intrinsically clamped to 1..4 (four branches, min 1). The runtime budget is
/// `AppSizing.contentMaxWidth − 2·contentGutter` ≈ 952 px at desktop, so this
/// returns 4 there; `MetricsSection` additionally caps the column count at the
/// card count (3), which is the live desktop layout.
int metricsColumnsFor(double width) => switch (width) {
  < 332 => 1,
  < 504 => 2,
  < 676 => 3,
  _ => 4,
};

/// Width of the card at [index] among [count] cards sharing [available] px.
///
/// Columns come from [metricsColumnsFor], capped at [count] so three cards
/// fill a wide row evenly instead of leaving an empty fourth column. A short
/// last row splits the full width among its cards, so no card sits alone
/// beside an empty cell (2 + 1 on phones). Called once per card, so an empty
/// card list never reaches the division.
double metricsCardWidth({
  required int index,
  required int count,
  required double available,
}) {
  RangeError.checkValidIndex(index, null, 'index', count);
  final columns = math.min(metricsColumnsFor(available), count);
  final lastRowStart = (count - 1) ~/ columns * columns;
  final perRow = switch (index >= lastRowStart) {
    true => count - lastRowStart,
    false => columns,
  };
  return (available - metricsGap * (perRow - 1)) / perRow;
}
