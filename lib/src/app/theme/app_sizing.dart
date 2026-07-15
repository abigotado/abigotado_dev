/// Layout size tokens for abigotado.dev.
///
/// These tokens govern the editor-shell layout (sidebar, content width,
/// gutters). They are distinct from the 600 px lite-mode compact breakpoint —
/// [editorBreakpoint] (900 px) is the threshold above which the sidebar is
/// shown.
abstract final class AppSizing {
  /// Maximum width of the main content column in pixels.
  ///
  /// Content sections constrain themselves to this width and left-align within
  /// the available pane.
  static const double contentMaxWidth = 1000;

  /// Fixed width of the file-explorer sidebar panel in pixels.
  ///
  /// Only shown when the viewport is at least [editorBreakpoint] wide.
  static const double sidebarWidth = 172;

  /// Viewport width breakpoint in pixels above which the sidebar is shown.
  ///
  /// This is the editor-layout breakpoint and is intentionally wider than the
  /// 600 px lite-mode compact breakpoint.
  static const double editorBreakpoint = 900;

  /// Maximum width of the terminal frame in pixels.
  ///
  /// Mirrors the previous `_maxWidth` literal in `TerminalFrame` so the value
  /// has a single named source of truth.
  static const double terminalMaxWidth = 720;

  /// Maximum width of the README document's content column in pixels.
  ///
  /// Narrower than [contentMaxWidth] — 760 px is a comfortable reading
  /// measure for the prose-heavy README document, distinct from the wider
  /// section-card grid the pitch uses.
  static const double readmeMaxWidth = 760;

  /// Fixed width of the sticky README preview panel in pixels.
  ///
  /// Only shown when the viewport is at least [readmePanelBreakpoint] wide.
  /// The panel owns this width itself (see `ReadmePreviewPanel`'s class doc)
  /// rather than an external wrapper, so hiding the panel fully reclaims the
  /// space instead of leaving a blank gap.
  static const double readmePanelWidth = 380;

  /// Viewport width breakpoint in pixels above which the README preview
  /// panel is shown.
  ///
  /// Must be at least [sidebarWidth] + [contentGutter] + [contentMaxWidth] +
  /// [readmePanelWidth] (172 + 24 + 1000 + 380 = 1576 px) so the pitch's
  /// content cards keep their full [contentMaxWidth] measure the moment the
  /// panel appears — a narrower breakpoint would squeeze the card column
  /// below 1000 px as soon as the panel claims its 380 px. 1600 clears that
  /// 1576 px floor with headroom; a guard test pins this invariant.
  static const double readmePanelBreakpoint = 1600;

  /// Horizontal padding applied inside each content section in pixels.
  static const double contentGutter = 24;

  /// Grid pitch for the living background in logical pixels.
  ///
  /// Distance between adjacent dot centres on both axes. Used by
  /// `layoutBackgroundDots` and `LivingBackgroundPainter` so there is a single
  /// source of truth for the dot-grid density.
  static const double backgroundDotSpacing = 48;
}
