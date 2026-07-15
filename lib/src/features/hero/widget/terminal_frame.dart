import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/app/theme/app_sizing.dart';
import 'package:abigotado_dev/src/app/widget/content_width.dart';
import 'package:abigotado_dev/src/app/widget/traffic_lights.dart';
import 'package:flutter/material.dart';

/// The terminal shell that frames the build-scenario hero: a dark, rounded
/// panel with macOS-style traffic-light dots and the command line that "runs"
/// the agents.
///
/// Layout is mobile-first, right-flush on wide viewports: the panel sits
/// inside [ContentWidth] at its default [AppSizing.contentMaxWidth] cap — the
/// SAME cap the content cards below it use — then an inner [Align] at
/// [Alignment.topRight] plus a [BoxConstraints] cap the visible panel itself
/// at [AppSizing.terminalMaxWidth] (720 px) and pin it to the right edge of
/// that shared measure. This is a deliberate owner ask: the panel's RIGHT
/// edge is flush with the content cards' right edge below it; the LEFT edge
/// is what indents on wide viewports now (the opposite of the previous
/// left-flush layout). Below roughly ~768 px of available content width the
/// outer [AppSizing.contentMaxWidth] cap is never reached, so this is a
/// no-op there — the panel fills the available width exactly as before. The
/// command line wraps softly so it never overflows on narrow screens.
///
/// The load-bearing width mechanism: `ReviewerCommentCard`'s
/// `width: double.infinity` forces the panel's [Column] to actually fill the
/// [AppSizing.terminalMaxWidth] cap instead of shrink-wrapping to its
/// narrowest child — removing that `width: double.infinity` would shrink the
/// whole panel back toward its command line's intrinsic width and break the
/// right-flush alignment this class provides.
///
/// [children] are stacked below the command line (agent status lines, reviewer
/// card, etc.).
class TerminalFrame extends StatelessWidget {
  /// Creates the terminal frame around [children].
  const TerminalFrame({required this.children, this.cursor, super.key});

  /// A public key on the panel [Container] itself (as opposed to the wider
  /// [ContentWidth]/[Align] wrappers it right-aligns within), so geometry
  /// tests can locate and measure the actual rendered panel.
  static const Key panelKey = Key('terminal-frame-panel');

  /// The content rendered inside the terminal body, below the command line.
  final List<Widget> children;

  /// An optional caret rendered after the command (the view supplies a blinking
  /// cursor in full mode; `null` in lite mode shows the bare command).
  final Widget? cursor;

  /// The headline command the agents "execute". This is a shell-command
  /// literal — like a code identifier, it is intentionally NOT localized
  /// (a CLI invocation reads the same in every language).
  static const String _command = r'$ agents build abigotado.dev --release';

  @override
  Widget build(BuildContext context) {
    // The terminal renders bare here; the DEBUG/RELEASE ribbon now wraps the
    // whole editor window at the shell level (see EditorShell), not this panel.
    return ContentWidth(
      child: Align(
        alignment: Alignment.topRight,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSizing.terminalMaxWidth,
          ),
          child: Container(
            key: panelKey,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: 14,
              children: [
                const TrafficLights(),
                _CommandLine(command: _command, cursor: cursor),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The monospace command prompt line. Wraps softly so it never overflows on
/// narrow screens (no fixed-width row, no horizontal scroll). An optional
/// [cursor] is appended inline after the command via [WidgetSpan].
class _CommandLine extends StatelessWidget {
  const _CommandLine({required this.command, this.cursor});

  final String command;
  final Widget? cursor;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontFamily: 'monospace',
      fontSize: 14,
      height: 1.4,
      color: AppColors.textPrimary,
    );

    return Text.rich(
      TextSpan(
        text: command,
        style: style,
        children: [
          if (cursor != null)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: cursor,
              ),
            ),
        ],
      ),
      softWrap: true,
    );
  }
}
