import 'package:abigotado_dev/src/features/readme/content/readme_skill_group.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';

/// The skills groups — source of truth for the README document's skills
/// section.
///
/// **To update the skills:** add or remove a [ReadmeSkillGroup] here. No
/// widget code changes are needed.
const List<ReadmeSkillGroup> readmeSkillGroups = [
  ReadmeSkillGroup(title: _t1, body: _b1),
  ReadmeSkillGroup(title: _t2, body: _b2),
  ReadmeSkillGroup(title: _t3, body: _b3),
  ReadmeSkillGroup(title: _t4, body: _b4),
  ReadmeSkillGroup(title: _t5, body: _b5),
];

// Top-level functions so the tear-offs above are compile-time constants
// (instance method tear-offs are not const in Dart).
String _t1(AppLocalizations l) => l.rm_sk1_t;
String _t2(AppLocalizations l) => l.rm_sk2_t;
String _t3(AppLocalizations l) => l.rm_sk3_t;
String _t4(AppLocalizations l) => l.rm_sk4_t;
String _t5(AppLocalizations l) => l.rm_sk5_t;
String _b1(AppLocalizations l) => l.rm_sk1_b;
String _b2(AppLocalizations l) => l.rm_sk2_b;
String _b3(AppLocalizations l) => l.rm_sk3_b;
String _b4(AppLocalizations l) => l.rm_sk4_b;
String _b5(AppLocalizations l) => l.rm_sk5_b;
