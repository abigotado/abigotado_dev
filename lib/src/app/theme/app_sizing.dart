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

  /// Horizontal padding applied inside each content section in pixels.
  static const double contentGutter = 24;

  /// Grid pitch for the living background in logical pixels.
  ///
  /// Distance between adjacent dot centres on both axes. Used by
  /// `layoutBackgroundDots` and `LivingBackgroundPainter` so there is a single
  /// source of truth for the dot-grid density.
  static const double backgroundDotSpacing = 48;
}
