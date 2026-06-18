import 'package:abigotado_dev/src/app/theme/app_sizing.dart';
import 'package:flutter/widgets.dart';

/// Constrains and left-aligns its [child] to a content column width.
///
/// Wraps [child] in `Align(topLeft) → ConstrainedBox(maxWidth) →
/// Padding(horizontal: AppSizing.contentGutter)`.
/// On viewports wider than [maxWidth] the child is capped and left-aligned;
/// on narrower viewports it fills the available width minus the gutter on each
/// side.
///
/// [maxWidth] defaults to [AppSizing.contentMaxWidth] (1000 px). Pass a
/// narrower value (e.g. [AppSizing.terminalMaxWidth] at 720 px) to cap at a
/// different width while keeping the same gutter alignment.
class ContentWidth extends StatelessWidget {
  /// Creates a content-width wrapper.
  const ContentWidth({
    required this.child,
    this.maxWidth = AppSizing.contentMaxWidth,
    super.key,
  });

  /// The widget to constrain and align.
  final Widget child;

  /// Maximum width of the content column in logical pixels.
  ///
  /// Defaults to [AppSizing.contentMaxWidth]. Callers that need a narrower cap
  /// (e.g. the terminal frame at [AppSizing.terminalMaxWidth]) pass their own
  /// value — the gutter and left-alignment behaviour is identical.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.contentGutter,
          ),
          child: child,
        ),
      ),
    );
  }
}
