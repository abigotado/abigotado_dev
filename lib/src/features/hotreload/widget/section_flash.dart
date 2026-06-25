import 'dart:async';

import 'package:abigotado_dev/src/app/state/hot_reload_notifier.dart';
import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/features/hotreload/flash_timing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps [child] and overlays a one-shot amber "rebuild" flash when the
/// hot-reload pulse fires, staggered by the section's [order] in the wave.
///
/// Mirrors `RevealOnScroll`: it listens to the app-level `hotReloadProvider`
/// pulse id and reads `effectsModeOf` to gate animation.
///
/// - **Full mode:** a new pulse schedules this section's amber-wash overlay
///   after `flashDelayForIndex(order)` and clears it after `kFlashAnimMs`.
///   Repeated pulses reschedule (rapid taps restart the wave cleanly).
/// - **Lite mode:** the wrapper is inert — it returns [child] unchanged,
///   schedules no timers, and paints no overlay (the project's "lite = no
///   animation" contract; reduced-motion-correct). A full→lite flip mid-flash
///   cancels the pending timers and removes the overlay (zero tickers).
///
/// The overlay is a decorative foreground layer wrapped in [IgnorePointer], so
/// it never intercepts taps and contributes no semantics node — the child's
/// own semantics stay reachable and unduplicated.
class SectionFlash extends ConsumerStatefulWidget {
  /// Creates a hot-reload flash wrapper for [child] at wave position [order].
  const SectionFlash({
    required this.order,
    required this.child,
    super.key,
  });

  /// The section's 0-based document position (0 = top), driving its stagger
  /// delay in the wave. Passed in by `LandingPage` from true visual order.
  final int order;

  /// The section content to wrap.
  final Widget child;

  @override
  ConsumerState<SectionFlash> createState() => _SectionFlashState();
}

class _SectionFlashState extends ConsumerState<SectionFlash> {
  Timer? _startTimer;
  Timer? _holdTimer;
  bool _active = false;
  EffectsMode _mode = EffectsMode.full;

  void _cancelTimers() {
    _startTimer?.cancel();
    _holdTimer?.cancel();
    _startTimer = null;
    _holdTimer = null;
  }

  /// Schedules this section's flash: amber wash on after the stagger delay,
  /// off after the hold. Reschedules cleanly on a repeated pulse.
  void _onPulse() {
    if (_mode != EffectsMode.full) return;
    _cancelTimers();
    _startTimer = Timer(flashDelayForIndex(widget.order), () {
      if (!mounted) return;
      setState(() => _active = true);
      _holdTimer = Timer(const Duration(milliseconds: kFlashAnimMs), () {
        if (!mounted) return;
        setState(() => _active = false);
      });
    });
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _mode = effectsModeOf(context, ref);
    // Side-effect listener (not a watch): a new pulse id schedules the flash.
    // Registered every build — Riverpod dedupes by provider, so it fires once
    // per pulse, not per rebuild.
    ref.listen<int>(hotReloadProvider, (_, _) => _onPulse());

    // Lite mode is inert: cancel any in-flight flash from a prior full session
    // (a mid-flash full→lite flip) and return the child untouched. Cancelling
    // a Timer here is side-effect-free (no setState); _active is irrelevant
    // because no overlay is rendered.
    if (_mode == EffectsMode.lite) {
      _cancelTimers();
      _active = false;
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: kFlashAnimMs),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: AppColors.accentAmber.withValues(
                  alpha: _active ? kFlashPeakOpacity : 0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
