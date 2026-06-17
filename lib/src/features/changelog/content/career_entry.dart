import 'package:abigotado_dev/src/core/content/localized_text.dart';
import 'package:flutter/foundation.dart';

/// One entry in the CHANGELOG.md career timeline.
///
/// [version] is an invariant version tag (e.g. `'v5.x'`) — the same in every
/// locale, rendered as the timeline label.
///
/// [org] and [what] are [LocalizedText] references — functions that, given the
/// active `AppLocalizations`, return the resolved text for the current locale.
/// Both resolve at render time so the list can be `const`.
///
/// **Not equatable by design:** career entries are static configuration, never
/// compared at runtime. Add/remove an entry by editing `careerEntries` in
/// `changelog_content.dart` — no widget code changes needed.
@immutable
class CareerEntry {
  /// Creates a career timeline entry.
  const CareerEntry({
    required this.version,
    required this.org,
    required this.what,
  });

  /// Invariant version tag, e.g. `'v5.x'`, `'v1.0'`. Never localized.
  final String version;

  /// The organization name after the em-dash separator, localized.
  /// Resolved via `org(l10n)` at render time.
  final LocalizedText org;

  /// One-line career description for this version, localized.
  /// Resolved via `what(l10n)` at render time.
  final LocalizedText what;
}
