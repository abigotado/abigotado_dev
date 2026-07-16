import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/app/widget/reveal/build_cascade_item.dart';
import 'package:abigotado_dev/src/app/widget/section_card.dart';
import 'package:abigotado_dev/src/features/pubspec/content/pubspec_content.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// The pubspec.yaml skills card.
///
/// Renders a code-editor-style card whose body is formatted as a real
/// `pubspec.yaml` file — keys, version constraints, and comments all
/// colour-coded with the project palette (see `AppColors`):
///
/// - Structural keys AND package names → `accentPurple`
/// - String values (`nikita_kovalenko`, the description, languages, `flexible`)
///   → `accentTeal`
/// - Version constraints (`^senior`, …) → `accentAmber`
/// - Trailing comments (`# plugins, Pigeon`) → `textHint`
///
/// **Card chrome:** delegated to the shared [SectionCard] — the bordered
/// surface, the `pubspec.yaml` title + localized `l10n.ch1` badge header, and
/// the hairline divider. This card supplies only the code body as its child.
///
/// **Code body:** all pubspec lines as a single `SelectableText.rich` /
/// `Text.rich` (monospace 13, height 1.7) wrapped in a
/// `SingleChildScrollView(scrollDirection: Axis.horizontal)` so long tokens
/// never wrap mid-line (mirrors the mockup `<pre>` block).
///
/// **Lines in order:**
/// ```yaml
/// name: nikita_kovalenko
/// description: {l10n.pubspec_description}
///
/// dependencies:
///   flutter_dart: ^senior
///   bloc_riverpod_signals: ^senior
///   architecture_ddd: ^senior
///   mobile_security: ^prod
///   ai_first_pipelines: ^evangelist
///   team_leadership: ^2.0.0-lead
///   kotlin_swift: ^basic  # plugins, Pigeon
///
/// environment:
///   languages: "ru | en C2 | es C2"
///   timezone: flexible
/// ```
///
/// **Accessibility:** the outermost node is
/// `Semantics(container: true, label: ..., child: ExcludeSemantics(...))`.
/// The decorative code tokens (version constraints, colons, indentation) are
/// excluded, but the skills themselves are the section's content, so the label
/// is the localized summary (`l10n.pubspec_a11y`) followed by the skill names
/// — generated from [pubspecDependencies] so it never drifts from the list.
///
/// **Section-build cascade:** the code body is wrapped in a single
/// `BuildCascadeItem(index: 0, count: 1)` — while beneath an in-progress
/// `RevealBuild` it fades/slides in as one unit (there is nothing to
/// stagger within a single card body). Outside a build in progress,
/// `BuildCascadeItem` is a no-op passthrough and this card's render is
/// unchanged.
class PubspecCard extends StatelessWidget {
  /// Creates the pubspec.yaml skills card.
  const PubspecCard({super.key});

  static const _mono = TextStyle(fontFamily: 'monospace');

  static const _keyStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    color: AppColors.accentPurple,
  );

  static const _valueStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    color: AppColors.accentTeal,
  );

  static const _versionStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    color: AppColors.accentAmber,
  );

  static const _commentStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    color: AppColors.textHint,
  );

  static const _neutralStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    color: AppColors.textPrimary,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Screen-reader announcement: the localized summary plus the skill names
    // themselves (the section's actual content), generated from the content
    // list so it never drifts. Version constraints / syntax stay decorative.
    final spokenSkills = pubspecDependencies
        .map((dep) => dep.package.split('_').map(_spokenWord).join(' '))
        .join(', ');
    final semanticsLabel = '${l10n.pubspec_a11y}: $spokenSkills';

    // Build dependency TextSpans by iterating pubspecDependencies so adding a
    // skill requires no widget edit — only the content layer changes.
    final depSpans = <TextSpan>[];
    for (final dep in pubspecDependencies) {
      // Each line: "\n  {package}: {version}" with optional trailing comment.
      final comment = dep.comment;
      depSpans.add(
        TextSpan(
          children: [
            const TextSpan(text: '\n  ', style: _neutralStyle),
            TextSpan(text: dep.package, style: _keyStyle),
            const TextSpan(text: ': ', style: _neutralStyle),
            TextSpan(text: dep.version, style: _versionStyle),
            if (comment != null)
              TextSpan(
                text: '  ${comment(l10n)}',
                style: _commentStyle,
              ),
          ],
        ),
      );
    }

    final codeSpan = TextSpan(
      style: _mono.copyWith(fontSize: 13, height: 1.7),
      children: [
        // name: nikita_kovalenko
        const TextSpan(text: 'name', style: _keyStyle),
        const TextSpan(text: ': ', style: _neutralStyle),
        const TextSpan(text: pubspecName, style: _valueStyle),
        // description: {pubspec_description}
        const TextSpan(text: '\n', style: _neutralStyle),
        const TextSpan(text: 'description', style: _keyStyle),
        const TextSpan(text: ': ', style: _neutralStyle),
        TextSpan(text: l10n.pubspec_description, style: _valueStyle),
        // blank line then dependencies:
        const TextSpan(text: '\n', style: _neutralStyle),
        const TextSpan(text: '\n', style: _neutralStyle),
        const TextSpan(text: 'dependencies', style: _keyStyle),
        const TextSpan(text: ':', style: _neutralStyle),
        // dependency lines (each starts with \n inside depSpans)
        ...depSpans,
        // blank line then environment:
        const TextSpan(text: '\n', style: _neutralStyle),
        const TextSpan(text: '\n', style: _neutralStyle),
        const TextSpan(text: 'environment', style: _keyStyle),
        const TextSpan(text: ':', style: _neutralStyle),
        // languages: "ru | en C2 | es C2"
        const TextSpan(text: '\n  ', style: _neutralStyle),
        const TextSpan(text: 'languages', style: _keyStyle),
        const TextSpan(text: ': ', style: _neutralStyle),
        const TextSpan(
          text: '"$pubspecLanguages"',
          style: _valueStyle,
        ),
        // timezone: flexible
        const TextSpan(text: '\n  ', style: _neutralStyle),
        const TextSpan(text: 'timezone', style: _keyStyle),
        const TextSpan(text: ': ', style: _neutralStyle),
        const TextSpan(text: 'flexible', style: _valueStyle),
      ],
    );

    return Semantics(
      container: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: SectionCard(
          title: 'pubspec.yaml',
          badge: l10n.ch1,
          // Code body — horizontal scroll prevents mid-token line wrapping.
          child: BuildCascadeItem(
            index: 0,
            count: 1,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text.rich(
                codeSpan,
                softWrap: false,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Humanizes one underscore-separated word of a package identifier for speech,
/// upper-casing the acronyms that would otherwise be read letter-by-letter as
/// lowercase noise. Everything else is spoken as-is (these are invariant tech
/// labels, not translated prose).
String _spokenWord(String word) => switch (word) {
  'ai' => 'AI',
  'ddd' => 'DDD',
  'bloc' => 'BLoC',
  _ => word,
};
