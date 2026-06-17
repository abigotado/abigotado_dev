import 'package:abigotado_dev/src/core/content/localized_text.dart';
import 'package:flutter/foundation.dart';

/// One dependency line in the pubspec.yaml skills card — a single skill.
///
/// [package] and [version] are locale-invariant code literals (they read the
/// same in every language, like a package name and a version constraint do);
/// [comment] is an optional localized trailing comment, resolved at render
/// via `comment?.call(l10n)`.
@immutable
class PubspecDependency {
  /// Creates a pubspec dependency entry.
  const PubspecDependency({
    required this.package,
    required this.version,
    this.comment,
  });

  /// Locale-invariant package identifier, e.g. `flutter_dart`. Rendered as a
  /// pubspec key (purple).
  final String package;

  /// Locale-invariant version constraint, e.g. `^senior`. Rendered amber.
  final String version;

  /// Optional localized trailing comment (e.g. `# plugins, Pigeon`).
  /// `null` = no comment on this line. Rendered in the hint colour.
  final LocalizedText? comment;
}
