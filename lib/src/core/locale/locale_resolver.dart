import 'dart:ui';

import 'package:abigotado_dev/src/core/locale/supported_locale.dart';
import 'package:abigotado_dev/src/core/locale/timezone_region.dart';

/// Resolves the effective [SupportedLocale] from the available signals,
/// in priority order:
///
/// 1. [stored] — a previously persisted manual user choice (always wins).
/// 2. [platformLocales] — the device/browser language list; the first locale
///    whose primary language subtag maps to a supported locale wins.
///    Region subtags are ignored automatically.
/// 3. [timeZoneId] — IANA timezone id used as a geographic heuristic.
/// 4. [SupportedLocale.en] — hard fallback.
///
/// Pure function — no side effects, no I/O. Unit-testable without a widget.
SupportedLocale resolveLocale({
  SupportedLocale? stored,
  List<Locale> platformLocales = const [],
  String? timeZoneId,
}) {
  if (stored != null) return stored;

  for (final loc in platformLocales) {
    final m = SupportedLocale.fromCode(loc.languageCode);
    if (m != null) return m;
  }

  final tz = localeForTimeZone(timeZoneId);
  if (tz != null) return tz;

  return SupportedLocale.en;
}
