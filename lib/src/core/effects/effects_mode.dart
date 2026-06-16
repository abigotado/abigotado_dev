/// The two animation / rendering modes the app supports.
///
/// ### Why an enum rather than a sealed class?
/// CLAUDE.md's NEVER rule for sealed classes applies to *widget-factory*
/// variants (where subclasses carry distinct widget trees). [EffectsMode]
/// is a pure domain value — it carries no UI behaviour — so a plain enum
/// is the correct, idiomatic Dart choice here, exactly like `SupportedLocale`.
enum EffectsMode {
  /// All animations and visual effects are enabled.
  full,

  /// Heavy animations are disabled; lightweight transitions only.
  lite,
}
