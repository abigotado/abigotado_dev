import 'package:abigotado_dev/src/core/content/localized_text.dart';
import 'package:abigotado_dev/src/features/readme/content/education_entry.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';

/// The education entries — source of truth for the README document's
/// education section.
///
/// **To update education:** add or remove an [EducationEntry] here. No widget
/// code changes are needed.
const List<EducationEntry> educationEntries = [
  EducationEntry(title: _t1, detail: _d1),
  EducationEntry(title: _t2, detail: _d2),
];

/// The certification lines — source of truth for the README document's
/// certifications list (rendered below [educationEntries]).
///
/// No wrapper type: each entry is a plain [LocalizedText] since a
/// certification is a single resolved line, unlike [EducationEntry]'s
/// title/detail pair.
const List<LocalizedText> certifications = [_cert1, _cert2];

// Top-level functions so the tear-offs above are compile-time constants
// (instance method tear-offs are not const in Dart).
String _t1(AppLocalizations l) => l.rm_edu1_t;
String _t2(AppLocalizations l) => l.rm_edu2_t;
String _d1(AppLocalizations l) => l.rm_edu1_d;
String _d2(AppLocalizations l) => l.rm_edu2_d;
String _cert1(AppLocalizations l) => l.rm_cert1;
String _cert2(AppLocalizations l) => l.rm_cert2;
