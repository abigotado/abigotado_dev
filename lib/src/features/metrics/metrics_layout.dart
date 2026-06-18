/// Pure layout helper for the metrics section grid.
library;

/// Number of metric-card columns for the width AVAILABLE to the grid — i.e. the
/// `LayoutBuilder`-local `maxWidth`, already net of the section's horizontal
/// padding (the LayoutBuilder sits inside both the 720 max-width clamp and the
/// 24px padding, so this width is post-clamp and post-padding).
///
/// Reproduces the mockup's CSS `repeat(auto-fit, minmax(160px, 1fr))`: a new
/// column appears only once every card can stay >=160px wide given the 12px
/// inter-card gaps. Thresholds: 1 col < 332 <= 2 col < 504 <= 3 col < 676 <= 4.
/// Intrinsically clamped to 1..4 (four branches, min 1). The runtime budget is
/// `AppSizing.contentMaxWidth − 2·contentGutter` ≈ 952 px at desktop, so 4
/// columns is the live desktop layout.
int metricsColumnsFor(double width) => switch (width) {
  < 332 => 1,
  < 504 => 2,
  < 676 => 3,
  _ => 4,
};
