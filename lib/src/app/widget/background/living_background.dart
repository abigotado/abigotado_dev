import 'dart:async';

import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/app/theme/app_sizing.dart';
import 'package:abigotado_dev/src/app/widget/background/background_dot.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The animation phase used by [LivingBackgroundPainter] when there is no
/// active ticker (lite mode or before the controller is created).
const double kStaticBackgroundT = 0;

/// Paints the living dot-grid background at animation phase [t].
///
/// Delegates grid layout to [layoutBackgroundDots], which places dots on a
/// deterministic floor-anchored grid and computes per-dot opacity via:
///
/// ```dart
/// opacity = kBaseOpacity + kOpacityAmp * sin(2 * pi * ((t + dotPhase) % 1.0))
/// ```
///
/// The `% 1.0` ensures the loop is seamless (`t=0` and `t=1` are identical).
/// [shouldRepaint] returns `true` whenever any of [t], [spacing], [color], or
/// [seed] changes.
final class LivingBackgroundPainter extends CustomPainter {
  /// Creates the background painter.
  const LivingBackgroundPainter({
    required this.t,
    required this.spacing,
    required this.color,
    required this.seed,
  });

  /// Normalised animation phase in `[0.0, 1.0)`.
  final double t;

  /// Grid pitch in logical pixels — distance between dot centres.
  final double spacing;

  /// Tint colour applied to every dot (opacity is applied per-dot from [t]).
  final Color color;

  /// Deterministic seed for per-dot phase offsets.
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final dots = layoutBackgroundDots(
      size: size,
      t: t,
      spacing: spacing,
      seed: seed,
    );
    final paint = Paint()..style = PaintingStyle.fill;
    for (final dot in dots) {
      paint.color = color.withValues(alpha: dot.opacity);
      canvas.drawCircle(dot.position, dot.radius, paint);
    }
  }

  @override
  bool shouldRepaint(LivingBackgroundPainter old) =>
      old.t != t ||
      old.spacing != spacing ||
      old.color != color ||
      old.seed != seed;
}

/// Perpetual decorative dot-grid backdrop behind the editor shell.
///
/// In full-effects mode, runs a single 8-second repeating [AnimationController]
/// that drives the opacity-breathing animation. In lite mode or when the OS
/// `prefers-reduced-motion` setting is active, no controller is created and the
/// grid is painted at the static phase [kStaticBackgroundT] — zero transient
/// callbacks.
///
/// The widget reacts live to the effects toggle: a post-frame `_reconcile` call
/// creates the controller when transitioning to full mode and disposes it when
/// transitioning away, so the toggle is always bidirectional. The state uses
/// [TickerProviderStateMixin] (not `SingleTickerProviderStateMixin`) because
/// the controller can be created and disposed multiple times over the widget's
/// lifetime.
///
/// Painting is [RepaintBoundary]-isolated and [ExcludeSemantics]-wrapped
/// (decorative — no accessible content).
class LivingBackground extends ConsumerStatefulWidget {
  /// Creates the living background.
  const LivingBackground({super.key});

  @override
  ConsumerState<LivingBackground> createState() => _LivingBackgroundState();
}

class _LivingBackgroundState extends ConsumerState<LivingBackground>
    with TickerProviderStateMixin {
  AnimationController? _controller;
  bool _reconcileScheduled = false;

  /// The latest desired state (full ⇒ wants a running controller), refreshed on
  /// every [build]. The coalesced post-frame reconcile reads THIS, never a
  /// captured value, so a rapid mode flip before the callback fires reconciles
  /// to the current mode — lite never gets a stray ticker, full never stays
  /// static.
  bool _wantController = false;

  @override
  Widget build(BuildContext context) {
    _wantController = effectsModeOf(context, ref) == EffectsMode.full;
    _reconcile();
    final controller = _controller;
    if (controller == null) return const _Backdrop(t: kStaticBackgroundT);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => _Backdrop(t: controller.value),
    );
  }

  void _reconcile() {
    // A controller cannot be created/disposed during build; defer to a
    // post-frame callback, coalesced via [_reconcileScheduled]. The callback
    // re-reads [_wantController] (the latest mode) and re-checks the controller
    // state, so intervening rebuilds/flips converge to the current mode.
    if (_wantController == (_controller != null) || _reconcileScheduled) return;
    _reconcileScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reconcileScheduled = false;
      if (!mounted || _wantController == (_controller != null)) return;
      setState(() {
        if (_wantController) {
          _controller = AnimationController(
            vsync: this,
            duration: const Duration(seconds: 8),
          );
          unawaited(_controller!.repeat());
        } else {
          _controller!.dispose();
          _controller = null;
        }
      });
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

/// Structural background layer: excludes semantics, isolates repaints via
/// [RepaintBoundary], and delegates painting to [LivingBackgroundPainter].
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: LivingBackgroundPainter(
            t: t,
            spacing: AppSizing.backgroundDotSpacing,
            color: AppColors.accentTeal,
            seed: 0,
          ),
        ),
      ),
    );
  }
}
