import 'dart:async';

import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/features/cta/widget/contacts_panel.dart';
import 'package:abigotado_dev/src/features/cta/widget/merge_button.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The merge-CTA section of the landing page.
///
/// Presents a bespoke "Merge nikita into your-project/main" button. Tapping
/// it transitions through [MergePhase.merging] to [MergePhase.merged], at
/// which point the contacts panel is revealed.
///
/// In full effects mode the reveal is a [FadeTransition]; in lite mode it is
/// an immediate render. The tap is idempotent: a second tap after merged (or
/// while merging) is a no-op.
class MergeCtaSection extends ConsumerStatefulWidget {
  /// Creates the merge-CTA section.
  const MergeCtaSection({super.key});

  @override
  ConsumerState<MergeCtaSection> createState() => _MergeCtaSectionState();
}

class _MergeCtaSectionState extends ConsumerState<MergeCtaSection>
    with SingleTickerProviderStateMixin {
  MergePhase _phase = MergePhase.idle;
  AnimationController? _controller;
  late EffectsMode _mode;

  /// Handles the merge button tap.
  ///
  /// Idempotent: a second tap while already [MergePhase.merging] or
  /// [MergePhase.merged] is a no-op. The mode is read from [_mode], which
  /// `build` resolves via `effectsModeOf` before this callback is wired.
  void _onMerge() {
    if (_phase != MergePhase.idle) return;
    switch (_mode) {
      case EffectsMode.lite:
        setState(() => _phase = MergePhase.merged);
      case EffectsMode.full:
        final controller = _controller = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        );
        controller.addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() => _phase = MergePhase.merged);
          }
        });
        setState(() => _phase = MergePhase.merging);
        unawaited(controller.forward());
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Resolve effects mode in build so a toggle during the session triggers a
    // rebuild — the tap handler reads the already-resolved `_mode` field.
    _mode = effectsModeOf(context, ref);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              MergeButton(
                phase: _phase,
                onPressed: _phase == MergePhase.merged ? null : _onMerge,
              ),
              if (_phase != MergePhase.idle)
                if (_controller != null)
                  FadeTransition(
                    opacity: _controller!,
                    child: const ContactsPanel(),
                  )
                else
                  const ContactsPanel(),
            ],
          ),
        ),
      ),
    );
  }
}
