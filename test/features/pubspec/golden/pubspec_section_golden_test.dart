@Tags(['golden'])
library;

import 'package:abigotado_dev/src/features/pubspec/widget/pubspec_section.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../golden/golden_harness.dart';

// Golden tests run on Linux CI only (tag `golden`, skipped by default). They
// catch pixel regressions the structural widget tests can't see — the colored
// code-token styling (keys/values/versions/comments), the SectionCard chrome,
// and the horizontal-scroll code body on a phone.
void main() {
  group('PubspecSection golden', () {
    testWidgets('en · desktop 1000', (tester) async {
      await pumpGoldenSection(
        tester,
        section: const PubspecSection(),
        surface: const Size(1000, 1400),
      );
      await expectLater(
        find.byType(PubspecSection),
        matchesGoldenFile('goldens/pubspec_section_en_desktop.png'),
      );
    });

    testWidgets('en · phone 390', (tester) async {
      await pumpGoldenSection(
        tester,
        section: const PubspecSection(),
        surface: const Size(390, 1600),
      );
      await expectLater(
        find.byType(PubspecSection),
        matchesGoldenFile('goldens/pubspec_section_en_phone.png'),
      );
    });
  });
}
