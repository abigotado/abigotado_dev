import 'package:abigotado_dev/src/core/locale/supported_locale.dart';

/// Maps an IANA timezone [id] to the [SupportedLocale] most likely expected
/// by users in that region, or `null` when the timezone is not recognised or
/// does not map to a supported locale with confidence.
///
/// Examples:
/// - `'Europe/Moscow'` → [SupportedLocale.ru]
/// - `'America/Bogota'` → [SupportedLocale.es]
/// - `'America/New_York'` → `null` (no single supported locale dominates)
///
/// Stub — implemented in the GREEN phase.
SupportedLocale? localeForTimeZone(String? id) => throw UnimplementedError();
