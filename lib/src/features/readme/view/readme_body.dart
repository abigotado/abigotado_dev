import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/app/widget/contact_link_tile.dart';
import 'package:abigotado_dev/src/core/content/contact_links.dart';
import 'package:abigotado_dev/src/core/content/localized_text.dart';
import 'package:abigotado_dev/src/features/readme/content/education_content.dart';
import 'package:abigotado_dev/src/features/readme/content/education_entry.dart';
import 'package:abigotado_dev/src/features/readme/content/experience_content.dart';
import 'package:abigotado_dev/src/features/readme/content/experience_entry.dart';
import 'package:abigotado_dev/src/features/readme/content/readme_skill_group.dart';
import 'package:abigotado_dev/src/features/readme/content/readme_skills_content.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The four anchor sections of the README document that the anchor bar and
/// scroll-spy can jump to.
///
/// A narrower set than `EditorFile`: the README document has its own internal
/// navigation (header/collaboration/about/AI/domains are always visible above
/// the fold, not anchor targets), distinct from the editor sidebar's
/// section-per-file model.
enum ReadmeAnchor {
  /// The work-experience section.
  experience,

  /// The skills section.
  skills,

  /// The education section.
  education,

  /// The contacts section.
  contacts,
}

/// The full content of the `README.md` document.
///
/// Renders the whole human-readable "about me" document: header,
/// collaboration formats, about, AI-first block, domains, experience,
/// skills, education, languages, and contacts. Each anchor-bearing section is
/// wrapped in a `KeyedSubtree` using the [GlobalKey] from [sectionKeys] so
/// `ReadmeView`'s anchor bar can `ensureVisible` it.
///
/// The [ReadmeBody.headerCrop] constructor renders ONLY the header,
/// collaboration, and about blocks (no [sectionKeys] needed — passes an empty
/// map) — used by the golden test and, from stage 2 onward, the right preview
/// panel seam.
class ReadmeBody extends ConsumerWidget {
  /// Creates the full README document body.
  ///
  /// [sectionKeys] must contain a key for every [ReadmeAnchor] value; callers
  /// that need the full document (e.g. `ReadmeView`) always provide a
  /// complete map.
  const ReadmeBody({required this.sectionKeys, super.key})
    : _headerCropOnly = false;

  /// Creates a header-only crop of the README document: header,
  /// collaboration, and about — nothing else.
  ///
  /// Used by the golden test and, from stage 2, the right-hand preview
  /// panel. [sectionKeys] is empty since none of the cropped sections carry
  /// an anchor.
  const ReadmeBody.headerCrop({super.key})
    : sectionKeys = const {},
      _headerCropOnly = true;

  /// One [GlobalKey] per [ReadmeAnchor], placed on the corresponding section.
  final Map<ReadmeAnchor, GlobalKey> sectionKeys;

  /// `true` for [ReadmeBody.headerCrop] — renders only header, collaboration,
  /// and about, skipping every anchor-bearing section below.
  final bool _headerCropOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 24,
      children: [
        _ReadmeHeader(name: l10n.name, role: l10n.rm_role),
        _ReadmeCollaboration(
          intro: l10n.rm_collab_intro,
          items: [
            l10n.rm_collab_staff,
            l10n.rm_collab_contract,
            l10n.rm_collab_team,
          ],
        ),
        _ReadmeProse(body: l10n.rm_about),
        if (!_headerCropOnly) ...[
          _ReadmeProse(body: l10n.rm_ai),
          _ReadmeProse(body: l10n.rm_domains),
          KeyedSubtree(
            key: sectionKeys[ReadmeAnchor.experience],
            child: _ReadmeExperience(
              heading: l10n.rm_h_experience,
              entries: experienceEntries,
              l10n: l10n,
            ),
          ),
          // SEAM: stage 3 inserts a «Проекты» / Projects block here, heading
          // key `rm_h_projects` already reserved in the arb files.
          KeyedSubtree(
            key: sectionKeys[ReadmeAnchor.skills],
            child: _ReadmeSkills(
              heading: l10n.rm_h_skills,
              groups: readmeSkillGroups,
              l10n: l10n,
            ),
          ),
          KeyedSubtree(
            key: sectionKeys[ReadmeAnchor.education],
            child: _ReadmeEducation(
              heading: l10n.rm_h_education,
              entries: educationEntries,
              certifications: certifications,
              l10n: l10n,
            ),
          ),
          _ReadmeLanguages(
            heading: l10n.rm_h_languages,
            body: l10n.rm_languages,
          ),
          KeyedSubtree(
            key: sectionKeys[ReadmeAnchor.contacts],
            child: _ReadmeContacts(heading: l10n.rm_h_contacts),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared text styles
// ---------------------------------------------------------------------------

/// Monospace section-heading style, shared by every `_Readme*` heading below.
const TextStyle _headingStyle = TextStyle(
  fontFamily: 'monospace',
  fontSize: 18,
  fontWeight: FontWeight.w600,
  color: AppColors.textPrimary,
);

/// Prose body style — regular (non-monospace) type for readable paragraphs.
const TextStyle _proseStyle = TextStyle(
  fontSize: 15,
  height: 1.6,
  color: AppColors.textMuted,
);

/// A section heading, rendered via a bare [RichText].
///
/// Every anchor-bearing heading here (experience/skills/education/contacts)
/// is deliberately the SAME localized word as its `ReadmeView` anchor-bar
/// chip (e.g. `l10n.rm_h_skills` == `l10n.rm_anchor_skills` == "Skills") —
/// a natural nav-word/heading-word echo, true in all three locales. Both
/// need to render that literal word on screen at once. `find.text()`
/// explicitly ignores standalone [RichText] widgets (only [Text]/[Text.rich]
/// match, per its `findRichText` doc), so using [RichText] here — while the
/// anchor chip stays a plain [Text] — lets both widgets carry the identical
/// word without one finder accidentally matching both. Visually and for
/// assistive tech this renders exactly like [Text]: [RichText] participates
/// in the semantics tree the same way.
class _ReadmeSectionHeading extends StatelessWidget {
  const _ReadmeSectionHeading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(text: text, style: _headingStyle),
    );
  }
}

// ---------------------------------------------------------------------------
// Header + collaboration + prose blocks
// ---------------------------------------------------------------------------

/// The document header: the localized [name] and [role] tagline.
class _ReadmeHeader extends StatelessWidget {
  const _ReadmeHeader({required this.name, required this.role});

  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          softWrap: true,
        ),
        Text(role, style: _proseStyle, softWrap: true),
      ],
    );
  }
}

/// The collaboration-formats block: an [intro] line followed by bulleted
/// [items] (one per collaboration format — in-house, contract, team).
class _ReadmeCollaboration extends StatelessWidget {
  const _ReadmeCollaboration({required this.intro, required this.items});

  final String intro;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Text(intro, style: _proseStyle, softWrap: true),
        for (final item in items) _ReadmeBullet(text: item),
      ],
    );
  }
}

/// A single-paragraph prose block (about / AI-first / domains).
class _ReadmeProse extends StatelessWidget {
  const _ReadmeProse({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    return Text(body, style: _proseStyle, softWrap: true);
  }
}

/// A single bulleted line — a leading "•" glyph plus the prose [text].
class _ReadmeBullet extends StatelessWidget {
  const _ReadmeBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        const Text('•', style: _proseStyle),
        Expanded(child: Text(text, style: _proseStyle, softWrap: true)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Experience
// ---------------------------------------------------------------------------

/// The work-experience section: [heading] followed by one card per
/// [ExperienceEntry].
class _ReadmeExperience extends StatelessWidget {
  const _ReadmeExperience({
    required this.heading,
    required this.entries,
    required this.l10n,
  });

  final String heading;
  final List<ExperienceEntry> entries;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: [
        _ReadmeSectionHeading(text: heading),
        for (final entry in entries)
          _ReadmeExperienceCard(entry: entry, l10n: l10n),
      ],
    );
  }
}

/// One work-experience entry: the org (plain text or link, per
/// [ExperienceEntry.url]), role, summary, and achievement bullets.
class _ReadmeExperienceCard extends StatelessWidget {
  const _ReadmeExperienceCard({required this.entry, required this.l10n});

  final ExperienceEntry entry;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    // Stage 1: every ExperienceEntry.url is null, so this always takes the
    // plain-text branch. The switch is here so stage 3 (per-entry link
    // targets) lands by filling in the non-null branch, not by restructuring
    // this widget.
    final orgWidget = switch (entry.url) {
      null => Text(
        entry.org(l10n),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        softWrap: true,
      ),
      final url => _ReadmeOrgLink(label: entry.org(l10n), url: url),
    };

    return Container(
      padding: const EdgeInsets.only(left: 18, top: 8, bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppColors.accentPurple.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          orgWidget,
          Text(
            entry.role(l10n),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: AppColors.accentTeal,
            ),
            softWrap: true,
          ),
          Text(entry.summary(l10n), style: _proseStyle, softWrap: true),
          for (final achievement in entry.achievements)
            _ReadmeBullet(text: achievement(l10n)),
        ],
      ),
    );
  }
}

/// A placeholder link-styled org label, wired for stage 3 once
/// [ExperienceEntry.url] entries stop being `null`.
///
/// Not reachable in stage 1 (every entry's `url` is `null`), kept here so
/// `_ReadmeExperienceCard`'s switch already has a real non-null branch.
class _ReadmeOrgLink extends StatelessWidget {
  const _ReadmeOrgLink({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      label: label,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.accentTeal,
        ),
        softWrap: true,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skills
// ---------------------------------------------------------------------------

/// The skills section: [heading] followed by one tile per [ReadmeSkillGroup].
class _ReadmeSkills extends StatelessWidget {
  const _ReadmeSkills({
    required this.heading,
    required this.groups,
    required this.l10n,
  });

  final String heading;
  final List<ReadmeSkillGroup> groups;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        _ReadmeSectionHeading(text: heading),
        for (final group in groups)
          _ReadmeSkillTile(
            title: group.title(l10n),
            body: group.body(l10n),
          ),
      ],
    );
  }
}

/// One skills-group tile: a bold [title] line and its prose [body].
class _ReadmeSkillTile extends StatelessWidget {
  const _ReadmeSkillTile({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          softWrap: true,
        ),
        Text(body, style: _proseStyle, softWrap: true),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Education
// ---------------------------------------------------------------------------

/// The education section: [heading], [entries], and [certifications].
class _ReadmeEducation extends StatelessWidget {
  const _ReadmeEducation({
    required this.heading,
    required this.entries,
    required this.certifications,
    required this.l10n,
  });

  final String heading;
  final List<EducationEntry> entries;
  final List<LocalizedText> certifications;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        _ReadmeSectionHeading(text: heading),
        for (final entry in entries)
          _ReadmeEducationEntry(
            title: entry.title(l10n),
            detail: entry.detail(l10n),
          ),
        for (final cert in certifications) _ReadmeBullet(text: cert(l10n)),
      ],
    );
  }
}

/// One education entry: a bold [title] line and its supporting [detail].
class _ReadmeEducationEntry extends StatelessWidget {
  const _ReadmeEducationEntry({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          softWrap: true,
        ),
        Text(detail, style: _proseStyle, softWrap: true),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Languages + contacts
// ---------------------------------------------------------------------------

/// The languages line: [heading] followed by the single resolved [body]
/// string (e.g. "Russian — native · English C2 · Spanish C2").
class _ReadmeLanguages extends StatelessWidget {
  const _ReadmeLanguages({required this.heading, required this.body});

  final String heading;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Text(heading, style: _headingStyle),
        Text(body, style: _proseStyle, softWrap: true),
      ],
    );
  }
}

/// The contacts section: [heading] followed by a [Wrap] of [ContactLinkTile]
/// widgets built from [contactLinks].
class _ReadmeContacts extends StatelessWidget {
  const _ReadmeContacts({required this.heading});

  final String heading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        _ReadmeSectionHeading(text: heading),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final link in contactLinks) ContactLinkTile(link: link),
          ],
        ),
      ],
    );
  }
}
