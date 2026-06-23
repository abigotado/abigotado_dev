import 'package:abigotado_dev/src/app/widget/editor_file.dart';

/// Fraction of viewport height below its top at which a section reveals.
///
/// A value of 0.85 means a section triggers reveal when its top edge enters
/// the lower 85% of the visible viewport — i.e. 85% of the way down from the
/// top of the visible window.
const double kRevealLineFraction = 0.85;

/// Returns alreadyRevealed ∪ {file : sectionTop <=
/// scrollOffset + viewportHeight * kRevealLineFraction} (the union is the
/// one-shot latch). Degenerate (viewportHeight <= 0 or empty sections)
/// returns alreadyRevealed unchanged, never throws. (Green pass.)
Set<EditorFile> revealedSet({
  required List<({EditorFile file, double offset})> sections,
  required double scrollOffset,
  required double viewportHeight,
  required Set<EditorFile> alreadyRevealed,
}) {
  if (viewportHeight <= 0 || sections.isEmpty) return alreadyRevealed;
  final line = scrollOffset + viewportHeight * kRevealLineFraction;
  return {
    ...alreadyRevealed,
    for (final s in sections)
      if (s.offset <= line) s.file,
  };
}
