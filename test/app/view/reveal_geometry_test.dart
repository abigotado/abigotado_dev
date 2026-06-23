import 'package:abigotado_dev/src/app/view/reveal_geometry.dart';
import 'package:abigotado_dev/src/app/widget/editor_file.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fixture: five sections in document order.
// offsets: fileHero=0, metrics=500, pubspec=1000, changelog=1500, contacts=2000
// ---------------------------------------------------------------------------

const List<({EditorFile file, double offset})> _sections = [
  (file: EditorFile.fileHero, offset: 0),
  (file: EditorFile.metrics, offset: 500),
  (file: EditorFile.pubspec, offset: 1000),
  (file: EditorFile.changelog, offset: 1500),
  (file: EditorFile.contacts, offset: 2000),
];

// vh=900 → reveal line at scrollOffset + 900*0.85 = scrollOffset + 765
const double _vh = 900;
const double _line = _vh * kRevealLineFraction; // 765.0

// ---------------------------------------------------------------------------
// Tests — ALL RED (revealedSet throws UnimplementedError)
// ---------------------------------------------------------------------------

void main() {
  group('revealedSet', () {
    group('above-fold', () {
      test('t0 above-fold revealed', () {
        // scrollOffset=0, line=765: fileHero(0)<=765 and metrics(500)<=765
        // are below the reveal line; contacts(2000) is not.
        // RED: revealedSet throws UnimplementedError.
        final result = revealedSet(
          sections: _sections,
          scrollOffset: 0,
          viewportHeight: _vh,
          alreadyRevealed: const {},
        );

        expect(
          result,
          containsAll(<EditorFile>[EditorFile.fileHero, EditorFile.metrics]),
          reason:
              'fileHero(0) and metrics(500) are both ≤ 765 at scrollOffset=0',
        );
        expect(
          result,
          isNot(contains(EditorFile.contacts)),
          reason: 'contacts(2000) is above the reveal line (2000 > 765)',
        );
      });
    });

    group('boundary', () {
      test('boundary inclusive: offset == line → revealed', () {
        // Section at offset 765.0 exactly; scrollOffset=0, vh=900, line=765.
        // 765 <= 765 → must be in result.
        // RED: throws.
        final onBoundary = [
          (file: EditorFile.fileHero, offset: 765.0),
        ];

        final result = revealedSet(
          sections: onBoundary,
          scrollOffset: 0,
          viewportHeight: _vh,
          alreadyRevealed: const {},
        );

        expect(
          result,
          contains(EditorFile.fileHero),
          reason:
              'section at exactly the reveal line must be revealed '
              '(boundary is inclusive)',
        );
      });

      test('boundary +epsilon not revealed', () {
        // Section at 765.01; scrollOffset=0, vh=900, line=765.
        // 765.01 > 765 → must NOT be in result.
        // RED: throws.
        const epsilon = 0.01;
        final justAbove = [
          (file: EditorFile.fileHero, offset: _line + epsilon),
        ];

        final result = revealedSet(
          sections: justAbove,
          scrollOffset: 0,
          viewportHeight: _vh,
          alreadyRevealed: const {},
        );

        expect(
          result,
          isNot(contains(EditorFile.fileHero)),
          reason: 'section 0.01 px above the reveal line must NOT be revealed',
        );
      });
    });

    group('latch', () {
      test(
        'already-revealed stays even when now below line',
        () {
          // contacts(2000) is above the reveal line at scrollOffset=0.
          // It is in alreadyRevealed → must survive in the union.
          // RED: throws.
          const alreadyRevealed = {EditorFile.contacts};

          final result = revealedSet(
            sections: _sections,
            scrollOffset: 0,
            viewportHeight: _vh,
            alreadyRevealed: alreadyRevealed,
          );

          expect(
            result,
            contains(EditorFile.contacts),
            reason:
                'alreadyRevealed must be latched in the result even when '
                'the section is now above the reveal line',
          );
        },
      );
    });

    group('below-fold', () {
      test('below-fold absent from fresh reveal', () {
        // contacts(2000) > 765 at scrollOffset=0, alreadyRevealed empty.
        // RED: throws.
        final result = revealedSet(
          sections: _sections,
          scrollOffset: 0,
          viewportHeight: _vh,
          alreadyRevealed: const {},
        );

        expect(
          result,
          isNot(contains(EditorFile.contacts)),
          reason:
              'contacts(2000) is above the reveal line — must be absent '
              'when not in alreadyRevealed',
        );
      });
    });

    group('growth', () {
      test(
        'growth is a superset, exactly one larger',
        () {
          // Start with alreadyRevealed={fileHero}.
          // scrollOffset so metrics(500) crosses the line:
          //   line = scrollOffset + 765 >= 500 → scrollOffset >= -265.
          //   Use scrollOffset=0 (line=765, metrics(500)<=765 ✓).
          //
          // After the call: result must contain fileHero AND metrics,
          // and be exactly one element larger than {fileHero}.
          //
          // RED: throws.
          const alreadyRevealed = {EditorFile.fileHero};

          final result = revealedSet(
            sections: _sections,
            scrollOffset: 0,
            viewportHeight: _vh,
            alreadyRevealed: alreadyRevealed,
          );

          expect(
            result.containsAll(<EditorFile>[
              EditorFile.fileHero,
              EditorFile.metrics,
            ]),
            isTrue,
            reason: 'result must contain all of alreadyRevealed plus metrics',
          );
          expect(
            result.length,
            equals(2),
            reason:
                'result must be exactly one element larger than '
                'alreadyRevealed (only metrics crossed the line)',
          );
          expect(
            result,
            contains(EditorFile.metrics),
            reason:
                'metrics(500) is on or below the reveal line at scrollOffset=0',
          );
        },
      );
    });

    group('degenerate', () {
      test(
        'viewportHeight <= 0 → alreadyRevealed unchanged, no throw',
        () {
          // Degenerate: vh=0 → line = 0*0.85 = 0, but contract says return
          // alreadyRevealed unchanged (never throw).
          // RED: currently throws UnimplementedError, but contract says "never
          // throws" for degenerate. After green pass this must return unchanged
          // AND not throw. The test is red because the UnimplementedError is a
          // throw.
          const alreadyRevealed = {EditorFile.metrics};

          final result = revealedSet(
            sections: _sections,
            scrollOffset: 0,
            viewportHeight: 0,
            alreadyRevealed: alreadyRevealed,
          );

          expect(
            result,
            equals(alreadyRevealed),
            reason:
                'viewportHeight=0 is degenerate — alreadyRevealed must '
                'be returned unchanged',
          );
        },
      );

      test(
        'empty sections → alreadyRevealed unchanged',
        () {
          // No sections to iterate — result must equal alreadyRevealed.
          // RED: throws UnimplementedError.
          const alreadyRevealed = {EditorFile.fileHero};

          final result = revealedSet(
            sections: const [],
            scrollOffset: 0,
            viewportHeight: _vh,
            alreadyRevealed: alreadyRevealed,
          );

          expect(
            result,
            equals(alreadyRevealed),
            reason: 'empty sections list must leave alreadyRevealed unchanged',
          );
        },
      );
    });
  });
}
