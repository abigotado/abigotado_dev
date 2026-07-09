import 'package:abigotado_dev/src/core/content/localized_text.dart';
import 'package:flutter/foundation.dart';

/// One skills group in the README document's skills section.
///
/// [title] is the group heading (e.g. "Flutter core"); [body] is a single
/// prose line listing the concrete skills in that group. Both are
/// [LocalizedText] — resolved at render time so the group list stays
/// `const`.
@immutable
class ReadmeSkillGroup {
  /// Creates a README skills group.
  const ReadmeSkillGroup({required this.title, required this.body});

  /// The group heading, localized.
  final LocalizedText title;

  /// The group's prose skill list, localized.
  final LocalizedText body;
}
