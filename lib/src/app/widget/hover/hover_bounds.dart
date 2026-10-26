import 'package:flutter/widgets.dart';

/// Marks the clip edge for the hover effects of the `HoverLift`s below it.
///
/// Wrap the clipping widget itself (for example a [ClipRect]) so this widget's
/// render box is the clip. A hovered `HoverLift` measures how far it sits from
/// this box's left and right edges and fits its glow into that room, so the
/// glow always fades out before the clip, whatever the layout leaves. Top and
/// bottom are not measured: there the clip is a scroll edge that cuts the card
/// itself as it scrolls past.
class HoverBounds extends InheritedWidget {
  /// Creates a hover clip boundary around [child].
  const HoverBounds({required super.child, super.key});

  /// The render box of the nearest [HoverBounds], or `null` outside one or
  /// before it has been laid out. Registers no dependency: callers measure on
  /// demand.
  static RenderBox? of(BuildContext context) {
    final box = context
        .getElementForInheritedWidgetOfExactType<HoverBounds>()
        ?.findRenderObject();
    return box is RenderBox && box.hasSize ? box : null;
  }

  @override
  bool updateShouldNotify(HoverBounds oldWidget) => false;
}
