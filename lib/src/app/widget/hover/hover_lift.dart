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
/// 1. `onEnter` sets `_hovered = true` → [AnimatedContainer.decoration]
///    transitions to the accent glow and the card scales up over
///    [kHoverAnimMs] milliseconds.
/// 2. `onHover` records the pointer position (and the card's size) on every
///    move → [AnimatedContainer.transform] leans the card toward the cursor
///    via `hoverTilt`, smoothing toward each new target over [kHoverAnimMs] ms.
/// 3. `onExit` clears `_hovered` and the pointer → decoration and transform
///    return to rest.
/// 4. `_resetScheduled`: a post-frame callback that resets `_hovered` (and the
///    pointer) if the widget is still mounted after a mode flip to lite.  This
///    prevents a stuck-hover when the mode changes programmatically while the
///    pointer is over the card (common on Flutter Web when the manual toggle
///    fires while the cursor hasn't moved).
///
/// ## Why [MouseRegion] is outermost
///
/// The [AnimatedContainer] may apply a 3-D tilt transform during hover.  If
/// [MouseRegion] were nested *inside* the transform, its hit-test geometry
/// would be the *tilted* bounding box, which shifts by ~2 px and causes the
/// region to exit itself immediately, creating a flicker loop.  Placing
/// [MouseRegion] outside the [AnimatedContainer] ensures the hover hit-test
/// always uses the *un-tilted* layout box.
///
/// ## Lite-mode / reduced-motion
///
/// In [EffectsMode.lite] (OS `prefers-reduced-motion`, compact viewport, or
/// manual toggle) the [AnimatedContainer] duration is [Duration.zero] and no
/// hover callbacks are wired.  The card renders [restDecoration] and
/// [Matrix4.identity()] at all times.
class HoverLift extends ConsumerStatefulWidget {
  /// Creates a hover-lift wrapper.
  ///
  /// [restDecoration] is the [BoxDecoration] shown when the card is at rest
  /// (not hovered) or in lite mode.  [padding] is applied to the
  /// [AnimatedContainer] so the content spacing is part of the animated
  /// surface.  [child] is the card content.
  const HoverLift({
    required this.restDecoration,
    required this.padding,
    required this.child,
    super.key,
  });

  /// The decoration applied to the [AnimatedContainer] at rest (not hovered)
  /// or in lite mode.  On hover in full mode this is passed to
  /// [hoverDecoration] so the border and glow animate while preserving
  /// [restDecoration]'s `color` and `borderRadius`.
  final BoxDecoration restDecoration;

  /// Padding applied inside the [AnimatedContainer].
  final EdgeInsetsGeometry padding;

  /// The card content displayed inside the animated surface.
  final Widget child;

  @override
  ConsumerState<HoverLift> createState() => _HoverLiftState();
}

final class _HoverLiftState extends ConsumerState<HoverLift> {
  bool _hovered = false;
  bool _resetScheduled = false;

  /// Cursor position in the card's local coordinates, updated on every hover
  /// move so the tilt follows the pointer. Null while not hovered (and for the
  /// frame between onEnter and the first onHover).
  Offset? _pointer;

  /// The card's laid-out size, captured alongside [_pointer] so the tilt can
  /// normalise the pointer offset from the centre.
  Size? _size;

  @override
  Widget build(BuildContext context) {
    final mode = effectsModeOf(context, ref);
    _scheduleResetIfStuck(mode);
    final isFull = mode == EffectsMode.full;
    return MouseRegion(
      onEnter: isFull ? (_) => _setHovered(true) : null,
      onHover: isFull ? (event) => _trackPointer(event.localPosition) : null,
      onExit: isFull ? (_) => _clearHover() : null,
      child: AnimatedContainer(
        duration: isFull
            ? const Duration(milliseconds: kHoverAnimMs)
            : Duration.zero,
        curve: Curves.easeOut,
        transform: hoverTilt(
          hovered: _hovered,
          pointer: _pointer,
          size: _size ?? Size.zero,
          mode: mode,
        ),
        transformAlignment: Alignment.center,
        decoration: hoverDecoration(
          hovered: _hovered,
          mode: mode,
          rest: widget.restDecoration,
        ),
        padding: widget.padding,
        child: widget.child,
      ),
    );
  }

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  /// Records the current pointer position (card-local) and the card's size so
  /// [hoverTilt] can lean the card toward the cursor. The size comes from this
  /// element's render box via [BuildContext.size] — the same coordinate space
  /// as the [MouseRegion]'s local hover position.
  void _trackPointer(Offset localPosition) {
    setState(() {
      _hovered = true;
      _pointer = localPosition;
      _size = context.size;
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
