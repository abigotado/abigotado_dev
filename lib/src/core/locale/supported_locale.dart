import 'dart:ui';

/// The set of locales the app supports.
///
/// ### Why an enum rather than a sealed class?
/// CLAUDE.md's NEVER rule for sealed classes applies to *widget-factory*
/// variants (where subclasses carry distinct widget trees). [SupportedLocale]
/// is a pure domain value — it carries no UI behaviour — so a plain enum is
/// the correct, idiomatic Dart choice here.
enum SupportedLocale {
  /// Russian — default for RU/BY/UA timezones when no stored choice exists.
  ru,

  /// English — the fallback locale.
  en,

  /// Spanish.
  es;

  /// Converts this domain value to the corresponding Flutter [Locale].
  Locale toLocale() => switch (this) {
    SupportedLocale.ru => const Locale('ru'),
    SupportedLocale.en => const Locale('en'),
    SupportedLocale.es => const Locale('es'),
  };

  /// Short display label for the locale switcher UI.
  String get label => switch (this) {
    SupportedLocale.ru => 'RU',
    SupportedLocale.en => 'EN',
    SupportedLocale.es => 'ES',
  };

  /// Returns the [SupportedLocale] matching the bare language [code]
  /// (`'ru'`, `'en'`, or `'es'`, case-insensitive), or `null` if [code] is
  /// unrecognised or `null`. The caller must supply a bare language code —
  /// region subtags (e.g. `'en-US'`) are not stripped and will return `null`.
  static SupportedLocale? fromCode(String? code) {
    if (code == null || code.isEmpty) return null;
    return switch (code.toLowerCase()) {
      'ru' => SupportedLocale.ru,
      'en' => SupportedLocale.en,
      'es' => SupportedLocale.es,
      _ => null,
    };
  }
}
