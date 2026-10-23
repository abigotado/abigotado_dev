import 'package:abigotado_dev/src/app/theme/app_sizing.dart';
import 'package:flutter/widgets.dart';

/// The editor's main content pane.
///
/// Left-aligns its [child] and applies the editor's left content gutter.
/// It does **not** cap width — each section self-caps via `ContentWidth`.
///
/// The pane is the clip boundary for its content: [ClipRect] sits outside the
/// left gutter, so a card's hover glow and lift may spill into that gutter
/// instead of being cut one gutter from the card, at the inner scroll view's
/// edge (the landing's scroll view does not clip; see `EditorScrollHost`).
/// [trailingGutter] gives the right side the same room. The pane does not pad
/// it itself: a scroll view placed inside would then draw its scrollbar one
/// gutter in from the pane edge. Scrollable content reads it through
/// [EditorPaneGutter.trailingOf] and pads inside its scroll view instead.
class EditorPane extends StatelessWidget {
  /// Creates the editor pane wrapper.
  const EditorPane({required this.child, this.trailingGutter = 0, super.key});

  /// The content to display inside the pane.
  final Widget child;

  /// The right-hand gutter the pane content should keep, in logical pixels.
  final double trailingGutter;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: AppSizing.contentGutter),
          child: EditorPaneGutter(trailing: trailingGutter, child: child),
        ),
      ),
    );
  }
}

/// Publishes the enclosing [EditorPane]'s trailing gutter to its content.
class EditorPaneGutter extends InheritedWidget {
  /// Creates the gutter scope.
  const EditorPaneGutter({
    required this.trailing,
    required super.child,
    super.key,
  });

  /// The right-hand gutter, in logical pixels.
  final double trailing;

  /// The trailing gutter of the nearest [EditorPane]; `0` outside one.
  static double trailingOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<EditorPaneGutter>()
          ?.trailing ??
      0;

  @override
  bool updateShouldNotify(EditorPaneGutter oldWidget) =>
      trailing != oldWidget.trailing;
}
