import 'package:abigotado_dev/src/app/view/scroll_spy_geometry.dart';
import 'package:abigotado_dev/src/app/widget/editor_file.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Shared fixture A — five sections in document order.
// offsets: fileHero=0, metrics=500, pubspec=1000, changelog=1500, contacts=2000
// maxScrollExtent: 1800 unless noted.
// ---------------------------------------------------------------------------

const List<({EditorFile file, double offset})> _sections = [
  (file: EditorFile.fileHero, offset: 0),
  (file: EditorFile.metrics, offset: 500),
  (file: EditorFile.pubspec, offset: 1000),
  (file: EditorFile.changelog, offset: 1500),
  (file: EditorFile.contacts, offset: 2000),
];

EditorFile _call(
  double scrollOffset, {
  double maxScrollExtent = 1800,
}) => activeEditorFile(
  sections: _sections,
  scrollOffset: scrollOffset,
  maxScrollExtent: maxScrollExtent,
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('activeEditorFile', () {
    // -------------------------------------------------------------------------
    group('first band', () {
      // 0 >= 1800-1=1799? No. LAST where offset <= 0+120=120:
      // fileHero(0)<=120. → fileHero.
      test(
        '0 → fileHero (at rest, activation window covers only first section)',
        () {
          expect(_call(0), equals(EditorFile.fileHero));
        },
      );

      // 119 >= 1799? No. LAST where offset <= 119+120=239:
      // fileHero(0)<=239, metrics(500)>239. → fileHero.
      test(
        '119 → fileHero (in first band, window does not yet reach metrics)',
        () {
          expect(_call(119), equals(EditorFile.fileHero));
        },
      );
    });

    // -------------------------------------------------------------------------
    group('activation boundary (379/380)', () {
      // 379 >= 1799? No. LAST where offset <= 379+120=499:
      // fileHero(0)<=499, metrics(500)>499. → fileHero (one px before).
      test(
        '379 → fileHero (379+120=499 < 500, one px before metrics boundary)',
        () {
          expect(_call(379), equals(EditorFile.fileHero));
        },
      );

      // 380 >= 1799? No. LAST where offset <= 380+120=500:
      // fileHero(0)<=500, metrics(500)<=500. → metrics (boundary inclusive).
      test('380 → metrics (380+120=500 ≤ 500, boundary is inclusive)', () {
        expect(_call(380), equals(EditorFile.metrics));
      });
    });

    // -------------------------------------------------------------------------
    group('mid-list', () {
      // 900 >= 1799? No. LAST where offset <= 900+120=1020:
      // fileHero(0), metrics(500), pubspec(1000)<=1020, changelog(1500)>1020.
      // → pubspec.
      test(
        '900 → pubspec (900+120=1020, last ≤ is pubspec(1000))',
        () {
          expect(_call(900), equals(EditorFile.pubspec));
        },
      );

      // 1400 >= 1799? No. LAST where offset <= 1400+120=1520:
      // changelog(1500)<=1520, contacts(2000)>1520. → changelog.
      test(
        '1400 → changelog (1400+120=1520, last ≤ is changelog(1500))',
        () {
          expect(_call(1400), equals(EditorFile.changelog));
        },
      );

      // 1700 >= 1799? No. LAST where offset <= 1700+120=1820:
      // changelog(1500)<=1820, contacts(2000)>1820. → changelog.
      // contacts at offset 2000 is unreachable by the activation rule — only
      // bottom-pin reaches it.
      test(
        '1700 → changelog (not bottom-pinned; contacts unreachable by rule)',
        () {
          expect(_call(1700), equals(EditorFile.changelog));
        },
      );
    });

    // -------------------------------------------------------------------------
    group('bottom-pin (1799/1800)', () {
      // 1799 >= maxScrollExtent(1800) - kBottomEpsilon(1) = 1799? Yes (>=).
      // → sections.last.file = contacts.
      test(
        '1799 → contacts (1799 >= 1800-1=1799, bottom-pin at epsilon boundary)',
        () {
          expect(_call(1799), equals(EditorFile.contacts));
        },
      );

      // 1800 >= 1799? Yes. Bottom-pin → contacts.
      // THE FIX-2 bug: without bottom-pin this stays changelog forever;
      // tapping contacts in the sidebar never highlights it.
      test(
        '1800 → contacts (at maxScrollExtent, bottom-pin → last)',
        () {
          expect(_call(1800), equals(EditorFile.contacts));
        },
      );
    });

    // -------------------------------------------------------------------------
    group('overscroll', () {
      // -30 >= 1799? No. LAST where offset <= -30+120=90:
      // fileHero(0)<=90, metrics(500)>90. → fileHero.
      test(
        '-30 → fileHero (overscroll-bounce negative offset falls to first)',
        () {
          expect(_call(-30), equals(EditorFile.fileHero));
        },
      );
    });

    // -------------------------------------------------------------------------
    group('degenerate single section', () {
      // Single section: 0 >= 0-1=-1? Yes. Bottom-pin and first both → fileHero.
      test('single section, scrollOffset=0, maxScrollExtent=0 → fileHero', () {
        expect(
          activeEditorFile(
            sections: const [(file: EditorFile.fileHero, offset: 0)],
            scrollOffset: 0,
            maxScrollExtent: 0,
          ),
          equals(EditorFile.fileHero),
        );
      });
    });

    // -------------------------------------------------------------------------
    group('everything fits — no scroll extent', () {
      // FIX-2 regression: before the `maxScrollExtent > 0` guard, the
      // bottom-pin condition was `0 >= 0 - 1 = -1`, which is true, so it
      // returned `sections.last.file` (contacts) even though no scrolling is
      // possible. After the fix the guard short-circuits and the activation
      // rule applies: threshold = 0 + 120 = 120; last section where offset
      // <= 120 is fileHero.
      //
      // This test uses 5-section Fixture A (fileHero=0 … contacts=2000) with
      // maxScrollExtent=0 to prove the multi-section case is handled correctly.
      // The single-section degenerate test above cannot catch this bug because
      // fileHero is both first and last — only a 5-section fixture
      // distinguishes "activation rule fell through to first" from
      // "bottom-pin fired".
      test(
        'five sections, maxScrollExtent=0, scrollOffset=0 '
        '→ fileHero (no spurious bottom-pin)',
        () {
          expect(
            _call(0, maxScrollExtent: 0),
            equals(EditorFile.fileHero),
            reason:
                'When the page fits entirely in the viewport '
                '(maxScrollExtent=0) the bottom-pin must not fire; '
                'the activation rule must return fileHero, not contacts.',
          );
        },
      );
    });
  });
}
