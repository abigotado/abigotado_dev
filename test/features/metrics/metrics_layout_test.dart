import 'package:abigotado_dev/src/features/metrics/metrics_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('metricsColumnsFor', () {
    group('1-column band (width < 332)', () {
      test('331.9 → 1', () {
        expect(metricsColumnsFor(331.9), equals(1));
      });

      test('320 → 1 (typical phone width)', () {
        expect(metricsColumnsFor(320), equals(1));
      });

      test('0 → 1 (lower clamp — never 0 columns)', () {
        expect(metricsColumnsFor(0), equals(1));
      });

      test('-10 → 1 (negative input clamped — never 0 columns)', () {
        expect(metricsColumnsFor(-10), equals(1));
      });
    });

    group('2-column band (332 ≤ width < 504)', () {
      test('332 → 2 (lower edge of 2-col band)', () {
        expect(metricsColumnsFor(332), equals(2));
      });

      test('503 → 2 (still inside 2-col band)', () {
        expect(metricsColumnsFor(503), equals(2));
      });
    });

    group('3-column band (504 ≤ width < 676)', () {
      test('504 → 3 (lower edge of 3-col band)', () {
        expect(metricsColumnsFor(504), equals(3));
      });

      test('675 → 3 (still inside 3-col band)', () {
        expect(metricsColumnsFor(675), equals(3));
      });
    });

    group('4-column band (width ≥ 676)', () {
      test('676 → 4 (lower edge of 4-col band)', () {
        expect(metricsColumnsFor(676), equals(4));
      });

      // Isolated pure-function upper-saturation; >672 is unreachable at
      // runtime under the 720 clamp. Tests the ≥676 → 4 branch saturates,
      // never returns 5.
      test('4000 → 4 (upper saturation — always clamped to 4)', () {
        expect(metricsColumnsFor(4000), equals(4));
      });
    });
  });
}
