@Tags(['golden'])
library;

import 'package:abigotado_dev/src/features/metrics/widget/metrics_section.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../golden/golden_harness.dart';

// Golden tests run on Linux CI only (tag `golden`, skipped by default). They
// catch pixel regressions the structural widget tests can't see — column-cap
// layout, card spacing, and the value/label styling of the three metrics.
void main() {
  group('MetricsSection golden', () {
    testWidgets('en · desktop 1000', (tester) async {
      await pumpGoldenSection(
        tester,
        section: const MetricsSection(),
        surface: const Size(1000, 1400),
      );
      await expectLater(
        find.byType(MetricsSection),
        matchesGoldenFile('goldens/metrics_section_en_desktop.png'),
      );
    });

    testWidgets('en · phone 390', (tester) async {
      await pumpGoldenSection(
        tester,
        section: const MetricsSection(),
        surface: const Size(390, 1600),
      );
      await expectLater(
        find.byType(MetricsSection),
        matchesGoldenFile('goldens/metrics_section_en_phone.png'),
      );
    });
  });
}
