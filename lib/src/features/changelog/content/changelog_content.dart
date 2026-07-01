import 'package:abigotado_dev/src/features/changelog/content/career_entry.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';

/// The career timeline — source of truth for the CHANGELOG.md card.
///
/// **To update the career:** add or remove a [CareerEntry] here.
/// No widget code changes are needed.
///
/// Entries are listed newest-first (highest version at index 0) to match the
/// CHANGELOG convention of most-recent-first.
const List<CareerEntry> careerEntries = [
  CareerEntry(version: 'v6.x', org: _org6, what: _what6),
  CareerEntry(version: 'v5.x', org: _org1, what: _what1),
  CareerEntry(version: 'v4.x', org: _org2, what: _what2),
  CareerEntry(version: 'v3.x', org: _org3, what: _what3),
  CareerEntry(version: 'v2.x', org: _org4, what: _what4),
  CareerEntry(version: 'v1.0', org: _org5, what: _what5),
];

// Top-level functions so the tear-offs above are compile-time constants
// (instance method tear-offs are not const in Dart).
String _org1(AppLocalizations l) => l.ch_org1;
String _org2(AppLocalizations l) => l.ch_org2;
String _org3(AppLocalizations l) => l.ch_org3;
String _org4(AppLocalizations l) => l.ch_org4;
String _org5(AppLocalizations l) => l.ch_org5;
String _org6(AppLocalizations l) => l.ch_org6;
String _what1(AppLocalizations l) => l.w1;
String _what2(AppLocalizations l) => l.w2;
String _what3(AppLocalizations l) => l.w3;
String _what4(AppLocalizations l) => l.w4;
String _what5(AppLocalizations l) => l.w5;
String _what6(AppLocalizations l) => l.w6;
