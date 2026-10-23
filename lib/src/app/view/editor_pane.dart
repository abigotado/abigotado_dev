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
/// On the right the pane's edge is the clip, which leaves only
/// `ContentWidth`'s own gutter on viewports up to its max width.
class EditorPane extends StatelessWidget {
  /// Creates the editor pane wrapper.
  const EditorPane({required this.child, super.key});

  /// The content to display inside the pane.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: AppSizing.contentGutter),
          child: child,
        ),
      ),
    );
  }
}
