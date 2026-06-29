@Tags(['golden'])
library;

import 'package:abigotado_dev/src/features/changelog/widget/changelog_section.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../golden/golden_harness.dart';

// Golden tests run on Linux CI only (tag `golden`, skipped by default). They
// catch pixel regressions the structural widget tests can't see — the
// left-accent-bar entry layout, the version-org em-dash line, and prose wrap.
void main() {
  group('ChangelogSection golden', () {
    testWidgets('en · desktop 1000', (tester) async {
      await pumpGoldenSection(
        tester,
        section: const ChangelogSection(),
        surface: const Size(1000, 1600),
      );
      await expectLater(
        find.byType(ChangelogSection),
        matchesGoldenFile('goldens/changelog_section_en_desktop.png'),
      );
    });

    testWidgets('en · phone 390', (tester) async {
      await pumpGoldenSection(
        tester,
        section: const ChangelogSection(),
        surface: const Size(390, 2000),
      );
      await expectLater(
        find.byType(ChangelogSection),
        matchesGoldenFile('goldens/changelog_section_en_phone.png'),
      );
    });
  });
}
