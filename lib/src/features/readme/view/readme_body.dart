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
///
/// ## Intended GREEN render (implemented in the green pass)
///
/// ```dart
/// Column(
///   crossAxisAlignment: CrossAxisAlignment.start,
///   mainAxisSize: MainAxisSize.min,
///   spacing: 24,
///   children: [
///     _ReadmeHeader(name: l10n.name, role: l10n.rm_role),
///     _ReadmeCollaboration(
///       intro: l10n.rm_collab_intro,
///       items: [
///         l10n.rm_collab_staff,
///         l10n.rm_collab_contract,
///         l10n.rm_collab_team,
///       ],
///     ),
///     _ReadmeAbout(body: l10n.rm_about),
///     if (!headerCropOnly) ...[
///       _ReadmeAiBlock(body: l10n.rm_ai),
///       _ReadmeDomains(body: l10n.rm_domains),
///       KeyedSubtree(
///         key: sectionKeys[ReadmeAnchor.experience],
///         child: _ReadmeExperience(
///           heading: l10n.rm_h_experience,
///           entries: experienceEntries,
///         ),
///       ),
///       // SEAM: stage 3 inserts a «Проекты» / Projects block here, heading
///       // key `rm_h_projects` already reserved in the arb files.
///       KeyedSubtree(
///         key: sectionKeys[ReadmeAnchor.skills],
///         child: _ReadmeSkills(
///           heading: l10n.rm_h_skills,
///           groups: readmeSkillGroups,
///         ),
///       ),
///       KeyedSubtree(
///         key: sectionKeys[ReadmeAnchor.education],
///         child: _ReadmeEducation(
///           heading: l10n.rm_h_education,
///           entries: educationEntries,
///           certifications: certifications,
///         ),
///       ),
///       _ReadmeLanguages(
///         heading: l10n.rm_h_languages,
///         body: l10n.rm_languages,
///       ),
///       KeyedSubtree(
///         key: sectionKeys[ReadmeAnchor.contacts],
///         child: _ReadmeContacts(
///           heading: l10n.rm_h_contacts,
///           children: [
///             for (final link in contactLinks) ContactLinkTile(link: link),
///           ],
///         ),
///       ),
///     ],
///   ],
/// )
/// ```
///
/// Org-link rule inside `_ReadmeExperience`'s per-entry card: `switch
/// (entry.url) { null => Text(org), _ => <link widget> }` — stage 1 always
/// takes the `null` branch (plain text), since every `ExperienceEntry.url` is
/// `null` for now.
///
/// ## THIS PASS
///
/// `build` returns [SizedBox.shrink] — the document renders nothing until the
/// green pass implements the tree sketched above.
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
  ///
  /// Unused in THIS PASS (both constructors render the same
  /// [SizedBox.shrink] stub); starts driving the `if (!headerCropOnly) ...`
  /// branch sketched above once the green pass lands.
  // ignore: unused_field
  final bool _headerCropOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) => const SizedBox.shrink();
}
