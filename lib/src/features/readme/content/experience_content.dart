import 'package:abigotado_dev/src/features/readme/content/experience_entry.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';

/// The work-experience timeline — source of truth for the README document's
/// experience section.
///
/// **To update the experience:** add or remove an [ExperienceEntry] here. No
/// widget code changes are needed.
///
/// Entries are listed newest-first, matching `careerEntries`' convention.
const List<ExperienceEntry> experienceEntries = [
  ExperienceEntry(
    org: _org1,
    role: _role1,
    summary: _sum1,
    achievements: [_exp1b1, _exp1b2, _exp1b3],
  ),
  ExperienceEntry(
    org: _org2,
    role: _role2,
    summary: _sum2,
    achievements: [_exp2b1, _exp2b2, _exp2b3, _exp2b4],
  ),
  ExperienceEntry(
    org: _org3,
    role: _role3,
    summary: _sum3,
    achievements: [_exp3b1, _exp3b2, _exp3b3],
  ),
  ExperienceEntry(
    org: _org4,
    role: _role4,
    summary: _sum4,
    achievements: [_exp4b1, _exp4b2, _exp4b3, _exp4b4],
  ),
  ExperienceEntry(
    org: _org5,
    role: _role5,
    summary: _sum5,
    achievements: [_exp5b1, _exp5b2, _exp5b3],
  ),
  ExperienceEntry(
    org: _org6,
    role: _role6,
    summary: _sum6,
    achievements: [_exp6b1, _exp6b2, _exp6b3],
  ),
];

// Top-level functions so the tear-offs above are compile-time constants
// (instance method tear-offs are not const in Dart).

// Entry 1 — Somnio Software.
String _org1(AppLocalizations l) => l.rm_exp1_org;
String _role1(AppLocalizations l) => l.rm_exp1_role;
String _sum1(AppLocalizations l) => l.rm_exp1_sum;
String _exp1b1(AppLocalizations l) => l.rm_exp1_b1;
String _exp1b2(AppLocalizations l) => l.rm_exp1_b2;
String _exp1b3(AppLocalizations l) => l.rm_exp1_b3;

// Entry 2 — FinHarbor.
String _org2(AppLocalizations l) => l.rm_exp2_org;
String _role2(AppLocalizations l) => l.rm_exp2_role;
String _sum2(AppLocalizations l) => l.rm_exp2_sum;
String _exp2b1(AppLocalizations l) => l.rm_exp2_b1;
String _exp2b2(AppLocalizations l) => l.rm_exp2_b2;
String _exp2b3(AppLocalizations l) => l.rm_exp2_b3;
String _exp2b4(AppLocalizations l) => l.rm_exp2_b4;

// Entry 3 — Цифровые технологии и платформы.
String _org3(AppLocalizations l) => l.rm_exp3_org;
String _role3(AppLocalizations l) => l.rm_exp3_role;
String _sum3(AppLocalizations l) => l.rm_exp3_sum;
String _exp3b1(AppLocalizations l) => l.rm_exp3_b1;
String _exp3b2(AppLocalizations l) => l.rm_exp3_b2;
String _exp3b3(AppLocalizations l) => l.rm_exp3_b3;

// Entry 4 — CPI Technologies GmbH.
String _org4(AppLocalizations l) => l.rm_exp4_org;
String _role4(AppLocalizations l) => l.rm_exp4_role;
String _sum4(AppLocalizations l) => l.rm_exp4_sum;
String _exp4b1(AppLocalizations l) => l.rm_exp4_b1;
String _exp4b2(AppLocalizations l) => l.rm_exp4_b2;
String _exp4b3(AppLocalizations l) => l.rm_exp4_b3;
String _exp4b4(AppLocalizations l) => l.rm_exp4_b4;

// Entry 5 — РЖД.
String _org5(AppLocalizations l) => l.rm_exp5_org;
String _role5(AppLocalizations l) => l.rm_exp5_role;
String _sum5(AppLocalizations l) => l.rm_exp5_sum;
String _exp5b1(AppLocalizations l) => l.rm_exp5_b1;
String _exp5b2(AppLocalizations l) => l.rm_exp5_b2;
String _exp5b3(AppLocalizations l) => l.rm_exp5_b3;

// Entry 6 — Nyamee.
String _org6(AppLocalizations l) => l.rm_exp6_org;
String _role6(AppLocalizations l) => l.rm_exp6_role;
String _sum6(AppLocalizations l) => l.rm_exp6_sum;
String _exp6b1(AppLocalizations l) => l.rm_exp6_b1;
String _exp6b2(AppLocalizations l) => l.rm_exp6_b2;
String _exp6b3(AppLocalizations l) => l.rm_exp6_b3;
