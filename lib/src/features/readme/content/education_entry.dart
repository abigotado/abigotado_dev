import 'package:abigotado_dev/src/core/content/localized_text.dart';
import 'package:flutter/foundation.dart';

/// One education entry in the README document's education section.
///
/// [title] is the degree + institution line; [detail] is the supporting
/// detail line (faculty, GPA, honors). Both are [LocalizedText] — resolved
/// at render time so the education list stays `const`.
@immutable
class EducationEntry {
  /// Creates a README education entry.
  const EducationEntry({required this.title, required this.detail});

  /// The degree + institution line, localized.
  final LocalizedText title;

  /// The supporting detail line, localized.
  final LocalizedText detail;
}
