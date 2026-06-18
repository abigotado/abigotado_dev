import 'package:abigotado_dev/src/app/theme/app_sizing.dart';
import 'package:flutter/widgets.dart';

/// The editor's main content pane.
///
/// Left-aligns its [child] and applies the editor's left content gutter.
/// It does **not** cap width — each section self-caps via `ContentWidth`.
class EditorPane extends StatelessWidget {
  /// Creates the editor pane wrapper.
  const EditorPane({required this.child, super.key});

  /// The content to display inside the pane.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: AppSizing.contentGutter),
        child: child,
      ),
    );
  }
}
