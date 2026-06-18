import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/app/theme/app_sizing.dart';
import 'package:abigotado_dev/src/app/widget/content_width.dart';
import 'package:abigotado_dev/src/app/widget/traffic_lights.dart';
import 'package:flutter/material.dart';

/// The terminal shell that frames the build-scenario hero: a dark, rounded
/// panel with macOS-style traffic-light dots and the command line that "runs"
/// the agents.
///
/// Layout is mobile-first: the panel is wrapped in [ContentWidth] with
/// [AppSizing.terminalMaxWidth] (720 px), so it shares the same left-edge
/// alignment as the content cards below it (both go through
/// `EditorPane → ContentWidth`). The command line wraps softly so it never
/// overflows on narrow screens.
///
/// [children] are stacked below the command line (agent status lines, reviewer
/// card, etc.).
class TerminalFrame extends StatelessWidget {
  /// Creates the terminal frame around [children].
  const TerminalFrame({required this.children, this.cursor, super.key});

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
    return ContentWidth(
      maxWidth: AppSizing.terminalMaxWidth,
      child: Container(
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
