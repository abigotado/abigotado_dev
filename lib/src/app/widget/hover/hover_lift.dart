import 'dart:math' as math;

import 'package:abigotado_dev/src/app/widget/hover/hover_bounds.dart';
import 'package:abigotado_dev/src/app/widget/hover/hover_visuals.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A wrapper that adds a mode-gated hover lift effect to its [child].
///
/// ## Full-mode contract
///
/// Outer [MouseRegion] callbacks (`onEnter` / `onHover` / `onExit`) are guarded
/// by `mode == EffectsMode.full` so a mouse over a card in lite mode never
/// triggers the tilt or glow.  In full mode:
///
/// 1. `onEnter` / `onHover` record the pointer position (and the card's size)
///    → the card scales up, leans toward the cursor via [hoverTargetPose], its
///    border turns to the accent and the glow fades in, smoothing toward each
///    new target over [kHoverAnimMs] ms. The glow is sized to the room between
///    the card and the nearest [HoverBounds] edge beside it
///    ([hoverGlowBlurFor]), so it always fades out before the clip.
/// 2. `onExit` clears the hover and the pointer → everything eases to rest.
/// 3. `_resetScheduled`: a post-frame callback that resets `_hovered` (and the
///    pointer) if the widget is still mounted after a mode flip to lite.  This
///    prevents a stuck-hover when the mode changes programmatically while the
///    pointer is over the card (common on Flutter Web when the manual toggle
///    fires while the cursor hasn't moved).
///
/// ## Why a [HoverPose] is animated, not a [Matrix4]
///
/// A [TweenAnimationBuilder] interpolates the [HoverPose] (tilt angles, scale,
/// lift) and [hoverTransform] rebuilds the matrix from it on every frame.
/// `AnimatedContainer.transform` would interpolate the matrix itself with
/// `Matrix4Tween`, which drops the perspective row for every intermediate
/// value: a card following the cursor rendered flat and snapped into
/// perspective only once the pointer stopped.
///
/// The widget tree has the same shape at rest and while hovered — a
/// conditional wrapper would remount [child] on hover and replay its own
/// reveal animations. At rest the transform is the identity (no layer) and the
/// decoration is [restDecoration] itself, so a resting card paints exactly as
/// a plain `Container(decoration: restDecoration)`.
///
/// ## Why [MouseRegion] is outermost
///
/// The card may be tilted in 3-D during hover.  If [MouseRegion] were nested
/// *inside* the transform, its hit-test geometry would be the *tilted*
/// bounding box, which shifts by a few pixels and causes the region to exit
/// itself immediately, creating a flicker loop.  Placing [MouseRegion] outside
/// ensures the hover hit-test always uses the *un-tilted* layout box.
///
/// ## Lite-mode / reduced-motion
///
/// In [EffectsMode.lite] (OS `prefers-reduced-motion`, compact viewport, or
/// manual toggle) no hover callbacks are wired, the target pose is always
/// [HoverPose.rest] and the animation duration is [Duration.zero], so no
/// ticker runs and the card renders [restDecoration] untransformed.
class HoverLift extends ConsumerStatefulWidget {
  /// Creates a hover-lift wrapper.
  ///
  /// [restDecoration] is the [BoxDecoration] shown when the card is at rest
  /// (not hovered) or in lite mode.  [padding] is applied inside the animated
  /// card surface so the content spacing is part of it.
  /// [child] is the card content.
  const HoverLift({
    required this.restDecoration,
    required this.padding,
    required this.child,
    super.key,
  });

  /// The card's decoration at rest (not hovered) or in lite mode.  On hover in
  /// full mode [hoverDecoration] animates its border toward the accent and
  /// adds the glow, preserving its `color` and `borderRadius`.
  final BoxDecoration restDecoration;

  /// Padding applied inside the animated card surface.
  final EdgeInsetsGeometry padding;

  /// The card content displayed inside the animated surface.
  final Widget child;

  @override
  ConsumerState<HoverLift> createState() => _HoverLiftState();
}

final class _HoverLiftState extends ConsumerState<HoverLift> {
  bool _hovered = false;
  bool _resetScheduled = false;

  /// Cursor position in the card's local coordinates, updated on enter and on
  /// every hover move so the tilt follows the pointer. Null while not hovered.
  Offset? _pointer;

  /// The card's laid-out size, captured alongside [_pointer] so the tilt can
  /// normalise the pointer offset from the centre.
  Size? _size;

  /// The glow blur fitted to the room beside the card, measured on every
  /// hover event. Kept after exit so the glow fades out at the same size.
  double _glowBlur = kHoverGlowBlur;
  bool _refitScheduled = false;

  @override
  Widget build(BuildContext context) {
    final mode = effectsModeOf(context, ref);
    _scheduleResetIfStuck(mode);
    final isFull = mode == EffectsMode.full;
    if (isFull && _hovered) _scheduleGlowRefit();
    return MouseRegion(
      onEnter: isFull ? (event) => _trackPointer(event.localPosition) : null,
      onHover: isFull ? (event) => _trackPointer(event.localPosition) : null,
      onExit: isFull ? (_) => _clearHover() : null,
      child: TweenAnimationBuilder<HoverPose>(
        tween: _HoverPoseTween(
          end: hoverTargetPose(
            hovered: _hovered,
            pointer: _pointer,
            size: _size ?? Size.zero,
            mode: mode,
          ),
        ),
        duration: isFull
            ? const Duration(milliseconds: kHoverAnimMs)
            : Duration.zero,
        curve: Curves.easeOut,
        builder: (context, pose, child) => Transform(
          transform: hoverTransform(pose),
          alignment: Alignment.center,
          child: Container(
            decoration: hoverDecoration(
              lift: pose.lift,
              rest: widget.restDecoration,
              glowBlur: _glowBlur,
            ),
            padding: widget.padding,
            child: child,
          ),
        ),
        child: widget.child,
      ),
    );
  }

  /// Records the current pointer position (card-local) and the card's size so
  /// [hoverTargetPose] can lean the card toward the cursor. The size comes from
  /// this element's render box via [BuildContext.size] — the same coordinate
  /// space as the [MouseRegion]'s local hover position.
  void _trackPointer(Offset localPosition) {
    setState(() {
      _hovered = true;
      _pointer = localPosition;
      _size = context.size;
      _glowBlur = _fittedGlowBlur();
    });
  }

  /// The glow blur that fits between this card and the nearer left or right
  /// edge of the enclosing [HoverBounds]; the full glow outside one. Measured
  /// on the untransformed card box, which is what [hoverTargetPose] moves by
  /// at most [kHoverMaxEdgeShift].
  double _fittedGlowBlur() {
    final bounds = HoverBounds.maybeBoxOf(context);
    final box = context.findRenderObject();
    if (bounds == null || box is! RenderBox || !box.hasSize) {
      return kHoverGlowBlur;
    }
    final left = box.localToGlobal(Offset.zero, ancestor: bounds).dx;
    final right = bounds.size.width - left - box.size.width;
    return hoverGlowBlurFor(math.min(left, right));
  }

  /// Re-measures the glow room once the frame's layout is done, while hovered.
  ///
  /// A viewport resize rebuilds this widget (`effectsModeOf` watches
  /// `MediaQuery.sizeOf`), so a card held under a still pointer re-fits its
  /// glow when the window narrows, not only on the next pointer event. A
  /// no-op unless the room actually changed the fitted blur.
  void _scheduleGlowRefit() {
    if (_refitScheduled) return;
    _refitScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refitScheduled = false;
      if (!mounted || !_hovered) return;
      final blur = _fittedGlowBlur();
      if (blur != _glowBlur) setState(() => _glowBlur = blur);
    });
  }

  /// Clears the hover state on pointer exit so the card returns to rest and the
  /// tilt un-tracks.
  void _clearHover() {
    if (!_hovered && _pointer == null) return;
    setState(() {
      _hovered = false;
      _pointer = null;
    });
  }

  /// Clears a stale [_hovered] flag via a post-frame callback when the mode
  /// flips from full to lite while the pointer is still over the card.
  ///
  /// [MouseRegion.onExit] does not fire on a programmatic mode change, so
  /// without this guard the card would stay painted as hovered after the flip.
  /// The flag is only scheduled once per mode-change frame; it is a no-op when
  /// [mode] is [EffectsMode.full], when [_hovered] is already `false`, or when
  /// a callback is already pending.
  void _scheduleResetIfStuck(EffectsMode mode) {
    if (mode == EffectsMode.full || !_hovered || _resetScheduled) return;
    _resetScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetScheduled = false;
      if (!mounted) return;
      setState(() {
        _hovered = false;
        _pointer = null;
      });
    });
  }
}

/// Interpolates a [HoverPose] field by field (see [HoverPose.lerp]).
final class _HoverPoseTween extends Tween<HoverPose> {
  _HoverPoseTween({required HoverPose super.end});

  @override
  HoverPose lerp(double t) => HoverPose.lerp(begin!, end!, t);
}
