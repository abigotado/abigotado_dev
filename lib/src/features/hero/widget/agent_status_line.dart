import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// One line in the terminal showing an agent's name and current status, e.g.
/// `planner   page structure ready`.
///
/// A widget with visual variants, so per CLAUDE.md it is a **sealed base
/// class** with a single [build] and abstract getters for the differing
/// primitives ([glyphColor], [agentName], [statusLabel]); the
/// structurally-different glyph widget (a pending dot / a running spinner slot
/// / a done check) is selected with `switch (this)`. Private factory
/// subclasses provide the variants.
///
/// The [agentName] is a code-identity literal (`planner` / `coder` /
/// `reviewer`) passed in by the caller — agent names are NOT localized (they
/// are identifiers, like a class name). The [statusLabel] IS localized and
/// comes from arb at the call site.
sealed class AgentStatusLine extends StatelessWidget {
  const AgentStatusLine._({
    required this.agentName,
    required this.statusLabel,
    super.key,
  });

  /// A not-yet-started agent: a dim dot glyph and muted text.
  const factory AgentStatusLine.pending({
    required String agentName,
    required String statusLabel,
    Key? key,
  }) = _PendingLine;

  /// A currently-running agent: a spinner slot (filled by the view's animated
  /// spinner when effects are on) and emphasised text.
  ///
  /// [spinner] is the widget rendered in the glyph slot — the view passes an
  /// animated spinner in full mode and a static glyph in lite mode. When `null`
  /// a static fallback dot is shown so the line is never empty.
  const factory AgentStatusLine.running({
    required String agentName,
    required String statusLabel,
    Widget? spinner,
    Key? key,
  }) = _RunningLine;

  /// A finished agent: a check glyph and success-toned text.
  const factory AgentStatusLine.done({
    required String agentName,
    required String statusLabel,
    Key? key,
  }) = _DoneLine;

  /// The agent identifier shown in the name column (a literal, not localized).
  final String agentName;

  /// The localized status text shown after the name.
  final String statusLabel;

  /// Colour applied to the glyph and the status label for this variant.
  Color get glyphColor;

  @override
  Widget build(BuildContext context) {
    final glyph = switch (this) {
      _PendingLine() => const Icon(
        Icons.fiber_manual_record,
        size: 10,
        color: AppColors.textHint,
      ),
      // The view fills `spinner` with an animated indicator in full mode; the
      // fallback dot keeps the slot non-empty in lite mode / contracts.
      final _RunningLine line =>
        line.spinner ??
            Icon(Icons.fiber_manual_record, size: 10, color: glyphColor),
      _DoneLine() => Icon(Icons.check, size: 14, color: glyphColor),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        SizedBox(width: 16, child: Center(child: glyph)),
        SizedBox(
          width: 72,
          child: Text(
            agentName,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            statusLabel,
            softWrap: true,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: glyphColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// Pending variant — dim dot, muted text.
final class _PendingLine extends AgentStatusLine {
  const _PendingLine({
    required super.agentName,
    required super.statusLabel,
    super.key,
  }) : super._();

  @override
  Color get glyphColor => AppColors.textHint;
}

/// Running variant — spinner slot, accent-toned text.
final class _RunningLine extends AgentStatusLine {
  const _RunningLine({
    required super.agentName,
    required super.statusLabel,
    this.spinner,
    super.key,
  }) : super._();

  /// The glyph-slot widget (typically an animated spinner) from the view.
  final Widget? spinner;

  @override
  Color get glyphColor => AppColors.accentAmber;
}

/// Done variant — check glyph, success-toned text.
final class _DoneLine extends AgentStatusLine {
  const _DoneLine({
    required super.agentName,
    required super.statusLabel,
    super.key,
  }) : super._();

  @override
  Color get glyphColor => AppColors.accentTeal;
}
