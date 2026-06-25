import 'package:abigotado_dev/src/features/hotreload/flash_timing.dart';
import 'package:flutter_test/flutter_test.dart';

// Pure unit tests — no widgets, no mocks, no ProviderContainer.
// All assertions are falsifiable: a hard-coded table or an off-by-one in the
// multiplier would break at least one of the three concrete cases PLUS the
// consistency checks that tie them to the constant.

void main() {
  group('flashDelayForIndex', () {
    group('order 0 (first section)', () {
      test('order 0 → Duration.zero (no stagger for the first section)', () {
        expect(flashDelayForIndex(0), equals(Duration.zero));
      });
    });

    group('order × kFlashStaggerMs formula', () {
      test('order 1 → Duration(milliseconds: 60)', () {
        expect(
          flashDelayForIndex(1),
          equals(const Duration(milliseconds: 60)),
        );
      });

      test('order 3 → Duration(milliseconds: 180)', () {
        expect(
          flashDelayForIndex(3),
          equals(const Duration(milliseconds: 180)),
        );
      });
    });

    // These tie the computed value to the exported constant, so a drift
    // between a hard-coded table and the constant is caught immediately.
    group(
      'constant consistency — result must equal order × kFlashStaggerMs',
      () {
        test(
          'flashDelayForIndex(1) == '
          'Duration(milliseconds: 1 * kFlashStaggerMs)',
          () {
            expect(
              flashDelayForIndex(1),
              equals(const Duration(milliseconds: 1 * kFlashStaggerMs)),
            );
          },
        );

        test(
          'flashDelayForIndex(5) == '
          'Duration(milliseconds: 5 * kFlashStaggerMs)',
          () {
            expect(
              flashDelayForIndex(5),
              equals(const Duration(milliseconds: 5 * kFlashStaggerMs)),
            );
          },
        );
      },
    );

    group('constants', () {
      test('kFlashAnimMs == 500', () {
        expect(kFlashAnimMs, equals(500));
      });

      test('kFlashStaggerMs == 60', () {
        expect(kFlashStaggerMs, equals(60));
      });

      test('kFlashPeakOpacity == 0.14', () {
        expect(kFlashPeakOpacity, equals(0.14));
      });
    });
  });
}
