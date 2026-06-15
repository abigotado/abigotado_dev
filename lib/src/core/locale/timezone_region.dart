import 'package:abigotado_dev/src/core/locale/supported_locale.dart';

/// Maps an IANA timezone [id] to the [SupportedLocale] most likely expected
/// by users in that region, or `null` when the timezone is not recognised or
/// does not map to a supported locale with confidence.
///
/// Examples:
/// - `'Europe/Moscow'` → [SupportedLocale.ru]
/// - `'America/Argentina/Buenos_Aires'` → [SupportedLocale.es]
/// - `'America/New_York'` → `null` (no single supported locale dominates)
///
/// The mapping is intentionally minimal and provisional; the live timezone
/// source (flutter_timezone / js interop) is deferred to a later feature.
SupportedLocale? localeForTimeZone(String? id) {
  if (id == null || id.isEmpty) return null;
  if (id.startsWith('America/Argentina/')) return SupportedLocale.es;
  return switch (id) {
    'America/Mexico_City' => SupportedLocale.es,
    'Europe/Moscow' => SupportedLocale.ru,
    'Asia/Yekaterinburg' => SupportedLocale.ru,
    _ => null,
  };
}
