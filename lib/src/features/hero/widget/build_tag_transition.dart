import 'dart:async' show unawaited;

import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/features/hero/state/build_phase.dart';
import 'package:abigotado_dev/src/features/hero/state/build_scenario_notifier.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Drives a `t` value (0 = DEBUG, 1 = RELEASE) and exposes it via [builder].
///
/// Full mode: a 250 ms [AnimationController] is created in
/// `didChangeDependencies` only when [effectsModeOf] returns
/// [EffectsMode.full]. A `ref.listen` on `buildScenarioProvider` detects the
/// phase → released transition and calls `controller.forward()`. The
/// controller is disposed in `dispose()`.
///
/// Lite / reduced-motion: no controller is created; [builder] is called with
/// `t = 0.0` (DEBUG) or `t = 1.0` (RELEASE) immediately — no animation.
class BuildTagTransition extends ConsumerStatefulWidget {
  /// Creates the build-tag transition driver.
  const BuildTagTransition({required this.builder, super.key});

  /// Called on every animation frame (or once for lite mode) with the current
  /// interpolation value: 0.0 = DEBUG, 1.0 = RELEASE.
  final Widget Function(BuildContext context, double t) builder;

  @override
  ConsumerState<BuildTagTransition> createState() => _BuildTagTransitionState();
}

class _BuildTagTransitionState extends ConsumerState<BuildTagTransition>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  /// Guards [didChangeDependencies] so initialization runs exactly once.
  bool _resolved = false;

  /// Holds `t` in lite mode where no controller is created.
  double _staticT = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolved) return;
    _resolved = true;

    final mode = effectsModeOf(context, ref);
    final released =
        ref.read(buildScenarioProvider.select((s) => s.phase)) ==
        BuildPhase.released;

    if (mode == EffectsMode.full) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 250),
        value: released ? 1.0 : 0.0,
      );
    } else {
      _staticT = released ? 1.0 : 0.0;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<BuildPhase>(
      buildScenarioProvider.select((s) => s.phase),
      (prev, next) {
        final c = _controller;
        if (next == BuildPhase.released) {
          if (c != null && !c.isCompleted) {
            unawaited(c.forward());
          } else if (c == null && _staticT != 1.0) {
            // Lite mode: phase jumped to released after mount — flip instantly.
            setState(() => _staticT = 1.0);
          }
        }
      },
    );

    final c = _controller;
    if (c == null) return widget.builder(context, _staticT);
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) => widget.builder(context, c.value),
    );
  }
}
