/// The phases the live "agents build the page" scenario moves through.
///
/// ### Why an enum rather than a sealed class?
/// CLAUDE.md's NEVER rule for sealed classes applies to *widget-factory*
/// variants (where subclasses carry distinct widget trees). [BuildPhase] is a
/// pure domain value — it carries no UI behaviour, only identifies which step
/// of the play-out is current — so a plain enum is the correct, idiomatic Dart
/// choice here, exactly like `SupportedLocale`.
enum BuildPhase {
  /// The planner is laying out the page structure.
  planning,

  /// The coder is building the sections.
  coding,

  /// The reviewer is examining the work (see [ReviewStatus]).
  reviewing,

  /// The build is shipped — DEBUG has flipped to RELEASE.
  released,
}

/// The reviewer's verdict within the [BuildPhase.reviewing] (and final) phase.
///
/// ### Why an enum rather than a sealed class?
/// Same rationale as [BuildPhase]: a pure domain value with no UI behaviour.
enum ReviewStatus {
  /// The reviewer is requesting changes (the comment card shows the nitpick).
  nitpicking,

  /// The reviewer has approved (the comment card shows the approval).
  approved,
}
