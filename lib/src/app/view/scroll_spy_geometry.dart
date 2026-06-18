import 'package:abigotado_dev/src/app/widget/editor_file.dart';

/// Pixels below the viewport top at which a section becomes active.
const double kActivationLine = 120;

/// Tolerance for the maxScrollExtent bottom-pin, in pixels.
const double kBottomEpsilon = 1;

/// Returns the file whose section is active for [scrollOffset].
///
/// [sections] is in document order and NON-EMPTY (the host never calls this
/// with an empty list — it no-ops on an empty offset map). Each record's
/// `offset` is the section top in scroll-content pixels (same space as
/// `ScrollController.offset`).
///
/// Rule:
///  - if `maxScrollExtent > 0` and
///    `scrollOffset >= maxScrollExtent - kBottomEpsilon`
///    → `sections.last.file`  (bottom-pin; the `> 0` guard prevents a page
///    that fits entirely in the viewport from being spuriously pinned to the
///    last section at scrollOffset 0)
///  - else the LAST section whose `offset <= scrollOffset + kActivationLine`
///  - else `sections.first.file`
EditorFile activeEditorFile({
  required List<({EditorFile file, double offset})> sections,
  required double scrollOffset,
  required double maxScrollExtent,
}) {
  // Bottom-pin: when scrolled to (or past) the last possible position, the
  // last section is always active regardless of its activation-line offset.
  // Requires maxScrollExtent > 0 so a fully-visible page (no scrolling
  // possible) does not spuriously pin to sections.last at scrollOffset 0.
  if (maxScrollExtent > 0 && scrollOffset >= maxScrollExtent - kBottomEpsilon) {
    return sections.last.file;
  }

  // Walk backwards to find the last section whose top has entered the
  // activation zone (i.e. its offset <= scrollOffset + kActivationLine).
  final threshold = scrollOffset + kActivationLine;
  for (var i = sections.length - 1; i >= 0; i--) {
    if (sections[i].offset <= threshold) {
      return sections[i].file;
    }
  }

  // No section qualifies yet — still above the first activation point.
  return sections.first.file;
}
