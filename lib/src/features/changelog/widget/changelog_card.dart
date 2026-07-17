import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/app/widget/reveal/build_cascade_item.dart';
import 'package:abigotado_dev/src/app/widget/section_card.dart';
import 'package:abigotado_dev/src/features/changelog/content/changelog_content.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// The CHANGELOG.md career-timeline card.
///
/// Renders the career history as a `CHANGELOG.md`-style file card using the
/// shared `SectionCard` chrome. Each `CareerEntry` from `careerEntries` becomes
/// a `_LogEntry`: a left-bordered block with a version/org label and a
/// description line.
///
/// ## Intended GREEN render (implemented in the green pass)
///
/// ```dart
/// SectionCard(
///   title: 'CHANGELOG.md',
///   badge: l10n.ch2,           // localized: 'career' / 'карьера' / 'carrera'
///   child: Column(
///     crossAxisAlignment: CrossAxisAlignment.start,
///     mainAxisSize: MainAxisSize.min,
///     children: [
///       for (final entry in careerEntries)
///         _LogEntry(
///           versionTag: '${entry.version} — ${entry.org(l10n)}',
///           what: entry.what(l10n),
///         ),
///     ],
///   ),
/// )
/// ```
///
/// The separator between the version tag and the resolved org is
/// `' — '` — a SPACE + U+2014 EM DASH + SPACE render constant.
///
/// `_LogEntry` renders a left-bordered block: a monospace 13 w600 tag line
/// (`AppColors.textPrimary`) and a 14pt description line
/// (`AppColors.textMuted`), separated by 2 px. Left border:
/// `AppColors.accentPurple` at 40 % opacity, 2 px wide, 18 px left padding,
/// 8 px top/bottom padding.
///
/// ## Section-build cascade
///
/// Each `_LogEntry` is wrapped in a `BuildCascadeItem` keyed by its position
/// among `careerEntries`, so — while beneath an in-progress `RevealBuild` —
/// the timeline entries fade/slide in one by one. Outside a build in
/// progress (including this pass, where nothing provides a build scope yet)
/// `BuildCascadeItem` is a no-op passthrough, so this card's render is
/// unchanged.
///
/// ## Accessibility
///
/// No `Semantics` wrapper is added here — the career timeline is readable
/// prose, so the screen reader announces it naturally element by element
/// (the opposite of `PubspecCard`'s decorative code body).
///
/// ## THIS PASS
///
/// [build] returns the full `SectionCard` + `_LogEntry` tree (GREEN pass).
class ChangelogCard extends StatelessWidget {
  /// Creates the CHANGELOG.md career-timeline card.
  const ChangelogCard({super.key});

  // U+2014 EM DASH with a space on each side — invariant render constant.
  static const String _emDashSeparator = ' — '; // U+2014

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SectionCard(
      title: 'CHANGELOG.md',
      badge: l10n.ch2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, entry) in careerEntries.indexed)
            BuildCascadeItem(
              index: i,
              count: careerEntries.length,
              child: _LogEntry(
                versionTag:
                    '${entry.version}$_emDashSeparator${entry.org(l10n)}',
                what: entry.what(l10n),
              ),
            ),
        ],
      ),
    );
  }
}

/// One entry in the CHANGELOG.md timeline.
///
/// Renders a left-bordered block: a monospace 13 w600 version/org tag line
/// and a 14 pt prose description line. The left accent bar uses
/// `AppColors.accentPurple` at 40 % opacity, 2 px wide. Both text lines
/// have `softWrap: true` so prose never clips on narrow viewports.
class _LogEntry extends StatelessWidget {
  const _LogEntry({required this.versionTag, required this.what});

  /// Pre-resolved version + em-dash + org string (e.g. "v5.x — FinHarbor").
  final String versionTag;

  /// Pre-resolved one-line career description (prose, may be long).
  final String what;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 18, top: 8, bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            // withValues(alpha:) is runtime — BoxDecoration is not const.
            color: AppColors.accentPurple.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          Text(
            versionTag,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            softWrap: true,
          ),
          Text(
            what,
            style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
            softWrap: true,
          ),
        ],
      ),
    );
  }
}
