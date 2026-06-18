import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// The set of files shown in the editor sidebar.
///
/// Each value maps to a real source file conceptually owned by that feature
/// section. The enum provides the stable filename literal, a Material icon, and
/// the localized clarity decode-label (the mockup's "intro / proof / skills /
/// career / reach me" words).
enum EditorFile {
  /// The hero terminal section — `hero.dart`.
  fileHero,

  /// The engineering-metrics section — `metrics.json`.
  metrics,

  /// The skills/pubspec section — `pubspec.yaml`.
  pubspec,

  /// The career/changelog section — `CHANGELOG.md`.
  changelog,

  /// The contacts/CTA section — `contacts.dart`.
  contacts;

  /// The invariant filename literal shown in the sidebar row.
  String get filename => switch (this) {
    EditorFile.fileHero => 'hero.dart',
    EditorFile.metrics => 'metrics.json',
    EditorFile.pubspec => 'pubspec.yaml',
    EditorFile.changelog => 'CHANGELOG.md',
    EditorFile.contacts => 'contacts.dart',
  };

  /// A Material [IconData] representing the file type.
  ///
  /// Returns an [IconData] value — never a built [Widget].
  IconData get icon => switch (this) {
    EditorFile.fileHero => Icons.code,
    EditorFile.metrics => Icons.data_object,
    EditorFile.pubspec => Icons.description,
    EditorFile.changelog => Icons.history,
    EditorFile.contacts => Icons.alternate_email,
  };

  /// The localized clarity decode-label for this file.
  ///
  /// These are the mockup's clarity words (intro / proof / skills / career /
  /// reach me), not filename echoes.
  String label(AppLocalizations l10n) => switch (this) {
    EditorFile.fileHero => l10n.file_hero,
    EditorFile.metrics => l10n.file_metrics,
    EditorFile.pubspec => l10n.file_pubspec,
    EditorFile.changelog => l10n.file_changelog,
    EditorFile.contacts => l10n.file_contacts,
  };
}
