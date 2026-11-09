import 'package:abigotado_dev/src/app/widget/hover/hover_bounds.dart';
import 'package:flutter/widgets.dart';

/// The editor's main content pane.
///
/// Left-aligns its [child]. It does **not** cap width — each section self-caps
/// via `ContentWidth`.
///
/// The pane is the clip boundary for its content, so a card's hover glow and
/// lift may spill into the gutters instead of being cut at the inner scroll
/// view's edge (the landing's scroll view does not clip; see
/// `EditorScrollHost`). The clip is also the [HoverBounds] for the cards
/// inside: wherever a layout leaves less room than the full glow needs (one
/// gutter on a compact viewport), a hovered card shrinks its glow to fade out
/// before the edge.
///
/// [gutter] is the horizontal room scrolling content keeps on both sides. The
/// pane does not pad it itself: a toolbar inside must still reach the pane
/// edges and a scroll view's scrollbar must stay on them. Content reads it
/// through [EditorPaneGutter.of] and pads inside its own scroll view instead.
class EditorPane extends StatelessWidget {
  /// Creates the editor pane wrapper.
  const EditorPane({required this.child, this.gutter = 0, super.key});

  /// The content to display inside the pane.
  final Widget child;

  /// The gutter pane content should keep on each side, in logical pixels.
  final double gutter;

  @override
  Widget build(BuildContext context) {
    return HoverBounds(
      child: ClipRect(
        child: Align(
          alignment: Alignment.topLeft,
          child: EditorPaneGutter(gutter: gutter, child: child),
        ),
      ),
    );
  }
}

/// Publishes the enclosing [EditorPane]'s gutter to its content.
class EditorPaneGutter extends InheritedWidget {
  /// Creates the gutter scope.
  const EditorPaneGutter({
    required this.gutter,
    required super.child,
    super.key,
  });

  /// The gutter on each side, in logical pixels.
  final double gutter;

  /// The gutter of the nearest [EditorPane]; `0` outside one.
  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EditorPaneGutter>()?.gutter ??
      0;

  @override
  bool updateShouldNotify(EditorPaneGutter oldWidget) =>
      gutter != oldWidget.gutter;
}
