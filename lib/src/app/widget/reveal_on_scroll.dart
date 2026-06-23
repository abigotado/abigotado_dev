import 'package:abigotado_dev/src/app/state/scroll_spy_notifier.dart';
import 'package:abigotado_dev/src/app/widget/editor_file.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Duration of the reveal slide+fade animation when effects are in full mode.
const int kRevealAnimMs = 420;

/// Vertical slide distance as a fraction of the widget's own height.
///
/// A small value (0.06 = 6%) gives a subtle upward drift — enough to feel
/// intentional without the content appearing to "jump".
const double kRevealSlideDy = 0.06;

/// Wraps [child] in a scroll-triggered reveal animation.
///
/// When [file]'s section has not yet crossed the reveal line, [child] is
/// rendered at opacity 0 with a slight downward offset. Once the section is
/// revealed (via [sectionRevealedProvider]), the widget animates to
/// opacity 1 / offset zero.
///
/// ### Semantics & hit-testing
/// [AnimatedOpacity] is used for the fade rather than `Visibility` or
/// `Offstage`, so the child's semantics node remains reachable by screen
/// readers even while the section is off-screen and opacity is 0. This
/// satisfies the a11y requirement that off-screen-settled content not be
/// excluded from the accessibility tree.
///
/// A widget at opacity 0 still participates in hit testing, so an unrevealed
/// section sitting in the lower viewport (below the reveal line but on-screen)
/// would otherwise let invisible interactive descendants (e.g. the contacts
/// CTA) intercept taps. [IgnorePointer] gates pointer input while unrevealed —
/// invisible content cannot be clicked — without touching semantics, so AT
/// users keep their (correct) access to the logically-present content.
///
/// ### Lite mode
/// When [EffectsMode.lite] is active (compact viewport or OS reduced-motion
/// or manual toggle), `duration` collapses to [Duration.zero] and `offset`
/// is always [Offset.zero], so the content appears immediately without any
/// animation. This satisfies the reduced-motion a11y requirement.
class RevealOnScroll extends ConsumerWidget {
  /// Creates a scroll-reveal wrapper for [child] keyed to [file].
  const RevealOnScroll({
    required this.file,
    required this.child,
    super.key,
  });

  /// The [EditorFile] whose reveal state drives this wrapper.
  final EditorFile file;

  /// The widget that will be revealed.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = effectsModeOf(context, ref);
    final revealed =
        mode == EffectsMode.lite || ref.watch(sectionRevealedProvider(file));
    final duration = mode == EffectsMode.lite
        ? Duration.zero
        : const Duration(milliseconds: kRevealAnimMs);
    return AnimatedSlide(
      offset: revealed ? Offset.zero : const Offset(0, kRevealSlideDy),
      duration: duration,
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: revealed ? 1 : 0,
        duration: duration,
        curve: Curves.easeOut,
        alwaysIncludeSemantics: true,
        // Block taps on still-invisible content (opacity 0 still hit-tests);
        // semantics stay reachable (IgnorePointer does not exclude them).
        child: IgnorePointer(ignoring: !revealed, child: child),
      ),
    );
  }
}
