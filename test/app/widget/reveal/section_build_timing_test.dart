import 'package:abigotado_dev/src/app/widget/reveal/section_build_timing.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Pure unit tests — no widgets, no mocks, no ProviderContainer. Mirrors
// flash_timing_test.dart's shape: every assertion is falsifiable — a wrong
// curve, a swapped window constant, or a floor-instead-of-ceil would break at
// least one case here.
//
// `Curve.transform` short-circuits to an EXACT `0.0`/`1.0` at `t == 0.0` /
// `t == 1.0` (see `package:flutter/src/animation/curves.dart`), so the
// doc-promised "endpoint exactness" of chromeOpacity/cascadeItemOpacity/
// cascadeItemSlideDy is asserted with `equals`, not `closeTo`.
// ---------------------------------------------------------------------------

void main() {
  group('chromeOpacity', () {
    group('boundary', () {
      test('t=0 (window start) → 0', () {
        expect(chromeOpacity(0), equals(0.0));
      });

      test('t=kChromeEndFrac (window end) → 1', () {
        expect(chromeOpacity(kChromeEndFrac), equals(1.0));
      });

      test('t=1 (well past the window) → 1', () {
        expect(chromeOpacity(1), equals(1.0));
      });
    });

    group('monotonic', () {
      test('non-decreasing across [0, 1] sampled', () {
        const steps = 20;
        var previous = chromeOpacity(0);
        for (var i = 1; i <= steps; i++) {
          final t = i / steps;
          final value = chromeOpacity(t);
          expect(
            value,
            greaterThanOrEqualTo(previous),
            reason:
                'chromeOpacity must never decrease as t increases '
                '(t=$t gave $value, previous was $previous)',
          );
          previous = value;
        }
      });
    });

    group('clamped outside window', () {
      test('t beyond kChromeEndFrac stays pinned at 1.0', () {
        for (final t in [0.2, 0.5, 0.8, 1.0]) {
          expect(
            chromeOpacity(t),
            equals(1.0),
            reason:
                't=$t is past kChromeEndFrac ($kChromeEndFrac) — the chrome '
                'must stay fully opaque for the rest of the build',
          );
        }
      });
    });

    group('formula consistency', () {
      test('matches the documented easeOut(local) formula off the window '
          'boundaries', () {
        for (final t in [0.02, 0.05, 0.08]) {
          final local =
              ((t - kChromeBeginFrac) / (kChromeEndFrac - kChromeBeginFrac))
                  .clamp(0.0, 1.0);
          final expected = Curves.easeOut.transform(local);
          expect(
            chromeOpacity(t),
            closeTo(expected, 1e-9),
            reason:
                'chromeOpacity($t) must equal Curves.easeOut.transform '
                'of the documented windowed-local formula',
          );
        }
      });
    });
  });

  group('headingCharsShown', () {
    group('below window', () {
      test('t <= kHeadingBeginFrac → 0', () {
        expect(headingCharsShown(0, 12), equals(0));
        expect(headingCharsShown(kHeadingBeginFrac, 12), equals(0));
      });
    });

    group('at/after window end', () {
      test('t == kHeadingEndFrac → length', () {
        expect(headingCharsShown(kHeadingEndFrac, 12), equals(12));
      });

      test('t beyond kHeadingEndFrac stays pinned at length', () {
        expect(headingCharsShown(1, 12), equals(12));
      });
    });

    group('monotonic', () {
      test('non-decreasing across [0, 1] sampled for a fixed length', () {
        const length = 20;
        const steps = 20;
        var previous = headingCharsShown(0, length);
        for (var i = 1; i <= steps; i++) {
          final t = i / steps;
          final value = headingCharsShown(t, length);
          expect(
            value,
            greaterThanOrEqualTo(previous),
            reason:
                'headingCharsShown must never decrease as t increases '
                '(t=$t gave $value, previous was $previous)',
          );
          previous = value;
        }
      });
    });

    group('zero length', () {
      test('length 0 → 0 for every sampled t', () {
        for (final t in [0.0, kHeadingBeginFrac, 0.25, kHeadingEndFrac, 1.0]) {
          expect(headingCharsShown(t, 0), equals(0));
        }
      });
    });

    group('ceil semantics', () {
      test('just past window start → at least one character shown (ceil, '
          'not floor)', () {
        // A floor-based implementation would return 0 here — only ceil
        // reveals the first character the instant t moves past the start.
        expect(headingCharsShown(kHeadingBeginFrac + 1e-6, 12), equals(1));
      });
    });
  });

  group('headingCursorVisible', () {
    group('before window', () {
      test('t=0 → false', () {
        expect(headingCursorVisible(0), isFalse);
      });
    });

    group('inside window (half-open, start inclusive)', () {
      test('t == kHeadingBeginFrac → true', () {
        expect(headingCursorVisible(kHeadingBeginFrac), isTrue);
      });

      test('t at window midpoint → true', () {
        expect(headingCursorVisible(0.25), isTrue);
      });
    });

    group('at/after window end (exclusive)', () {
      test('t == kHeadingEndFrac → false', () {
        // The cursor must vanish the INSTANT typing completes — not one
        // frame later. An implementation using an inclusive upper bound
        // would fail exactly here.
        expect(headingCursorVisible(kHeadingEndFrac), isFalse);
      });

      test('t well past kHeadingEndFrac → false', () {
        expect(headingCursorVisible(1), isFalse);
      });
    });
  });

  group('cascadeItemInterval', () {
    group('count <= 1 clamp', () {
      test('count=1 → the full cascade window regardless of index (no '
          'division by zero)', () {
        final interval = cascadeItemInterval(0, 1);
        expect(interval.begin, equals(kCascadeBeginFrac));
        expect(interval.end, equals(kCascadeEndFrac));
      });

      test(
        'count=0 is well-defined — never throws, never NaN (there is no '
        'item to render, so the specific value returned is unconstrained)',
        () {
          late ({double begin, double end}) result;
          expect(() => result = cascadeItemInterval(0, 0), returnsNormally);
          expect(result.begin.isNaN, isFalse);
          expect(result.end.isNaN, isFalse);
        },
      );
    });

    group('count=5 (evenly staggered, unclamped step)', () {
      test('index 0 begins exactly at kCascadeBeginFrac', () {
        expect(cascadeItemInterval(0, 5).begin, equals(kCascadeBeginFrac));
      });

      test('every index ends exactly at kCascadeEndFrac', () {
        for (var i = 0; i < 5; i++) {
          expect(
            cascadeItemInterval(i, 5).end,
            equals(kCascadeEndFrac),
            reason:
                'index $i must settle at exactly the moment the whole '
                'build closes',
          );
        }
      });

      test('begins strictly increase by index (fixed, unclamped stagger '
          'step)', () {
        final begins = [
          for (var i = 0; i < 5; i++) cascadeItemInterval(i, 5).begin,
        ];
        for (var i = 0; i < begins.length - 1; i++) {
          expect(
            begins[i + 1],
            greaterThan(begins[i]),
            reason: 'item ${i + 1} must start strictly after item $i',
          );
        }
      });
    });

    group('large count=40 (compressed/clamped step)', () {
      test('every index has begin <= end and neither is NaN', () {
        for (var i = 0; i < 40; i++) {
          final interval = cascadeItemInterval(i, 40);
          expect(interval.begin.isNaN, isFalse, reason: 'index $i begin');
          expect(interval.end.isNaN, isFalse, reason: 'index $i end');
          expect(
            interval.begin,
            lessThanOrEqualTo(interval.end),
            reason:
                'index $i must have a valid (possibly zero-width) '
                'interval',
          );
        }
      });

      test('the last index never exceeds kCascadeEndFrac (this is exactly '
          'why the step divides by count - 1, not count)', () {
        expect(
          cascadeItemInterval(39, 40).begin,
          lessThanOrEqualTo(kCascadeEndFrac),
        );
      });
    });
  });

  group('cascadeItemOpacity', () {
    group('before own interval', () {
      test('t <= begin → 0.0', () {
        final begin = cascadeItemInterval(2, 5).begin;
        expect(cascadeItemOpacity(0.3, 2, 5), equals(0.0));
        expect(cascadeItemOpacity(begin, 2, 5), equals(0.0));
      });
    });

    group('at/after own interval end', () {
      test('t == end → exactly 1.0', () {
        expect(cascadeItemOpacity(kCascadeEndFrac, 2, 5), equals(1.0));
      });
    });

    group('midpoint', () {
      test('strictly between begin and end → strictly between 0 and 1', () {
        final interval = cascadeItemInterval(2, 5);
        final mid = (interval.begin + interval.end) / 2;
        final value = cascadeItemOpacity(mid, 2, 5);
        expect(value, greaterThan(0.0));
        expect(value, lessThan(1.0));
      });
    });

    group('count <= 1 edge', () {
      test('count=1, index=0 does not throw at any t', () {
        for (final t in [0.0, 0.5, 1.0]) {
          expect(() => cascadeItemOpacity(t, 0, 1), returnsNormally);
        }
      });

      test('count=0, index=0 does not throw at any t', () {
        for (final t in [0.0, 0.5, 1.0]) {
          expect(() => cascadeItemOpacity(t, 0, 0), returnsNormally);
        }
      });
    });

    group('zero-width interval guard (large count)', () {
      // count=40's last index (39) degenerates to begin == end ==
      // kCascadeEndFrac — the formula's local = (t-begin)/(end-begin) would
      // divide 0/0 without the documented step-function guard.
      test('never produces NaN — treated as a step function at begin', () {
        expect(cascadeItemOpacity(0.5, 39, 40), equals(0.0));
        expect(cascadeItemOpacity(1, 39, 40), equals(1.0));
      });
    });
  });

  group('cascadeItemSlideDy', () {
    group('before own interval', () {
      test('t <= begin → kBuildSlideDy', () {
        final begin = cascadeItemInterval(2, 5).begin;
        expect(cascadeItemSlideDy(0.3, 2, 5), equals(kBuildSlideDy));
        expect(cascadeItemSlideDy(begin, 2, 5), equals(kBuildSlideDy));
      });
    });

    group('at/after own interval end', () {
      test('t == end → exactly 0.0', () {
        expect(cascadeItemSlideDy(kCascadeEndFrac, 2, 5), equals(0.0));
      });
    });

    group('midpoint', () {
      test('strictly between begin and end → strictly between 0 and '
          'kBuildSlideDy', () {
        final interval = cascadeItemInterval(2, 5);
        final mid = (interval.begin + interval.end) / 2;
        final value = cascadeItemSlideDy(mid, 2, 5);
        expect(value, greaterThan(0.0));
        expect(value, lessThan(kBuildSlideDy));
      });
    });

    group('count <= 1 edge', () {
      test('count=1, index=0 does not throw at any t', () {
        for (final t in [0.0, 0.5, 1.0]) {
          expect(() => cascadeItemSlideDy(t, 0, 1), returnsNormally);
        }
      });

      test('count=0, index=0 does not throw at any t', () {
        for (final t in [0.0, 0.5, 1.0]) {
          expect(() => cascadeItemSlideDy(t, 0, 0), returnsNormally);
        }
      });
    });

    group('zero-width interval guard (large count)', () {
      test('never produces NaN — treated as a step function at begin', () {
        expect(cascadeItemSlideDy(0.5, 39, 40), equals(kBuildSlideDy));
        expect(cascadeItemSlideDy(1, 39, 40), equals(0.0));
      });
    });
  });
}
