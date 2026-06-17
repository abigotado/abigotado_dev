import 'package:abigotado_dev/src/features/pubspec/content/pubspec_dependency.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';

/// The pubspec `name:` value — the author's package-style handle (invariant).
const String pubspecName = 'nikita_kovalenko';

/// The pubspec `languages:` value — CEFR levels, identical in every locale.
const String pubspecLanguages = 'ru | en C2 | es C2';

/// The skills, as pubspec dependencies. **Edit this list to update skills:**
/// add/remove a [PubspecDependency]; a line with a localized comment also
/// needs its arb key. Order is render order.
const List<PubspecDependency> pubspecDependencies = [
  PubspecDependency(package: 'flutter_dart', version: '^senior'),
  PubspecDependency(package: 'bloc_riverpod_signals', version: '^senior'),
  PubspecDependency(package: 'architecture_ddd', version: '^senior'),
  PubspecDependency(package: 'mobile_security', version: '^prod'),
  PubspecDependency(package: 'ai_first_pipelines', version: '^evangelist'),
  PubspecDependency(package: 'team_leadership', version: '^2.0.0-lead'),
  PubspecDependency(
    package: 'kotlin_swift',
    version: '^basic',
    comment: _pluginsComment,
  ),
];

/// Localized trailing comment for the kotlin_swift line (`# plugins, Pigeon`).
/// Top-level fn so the tear-off above is a compile-time constant.
String _pluginsComment(AppLocalizations l10n) => l10n.pcm;
