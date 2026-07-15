@Tags(['golden'])
library;

import 'package:abigotado_dev/src/features/readme/view/readme_body.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../golden/golden_harness.dart';

// Golden tests run on Linux CI only (tag `golden`, skipped by default). They
// catch pixel regressions the structural widget tests can't see — the
// header/collaboration/about layout, prose wrap, and reading-measure width.
//
// Baselines are generated on Linux CI post-merge (see
// .github/workflows/golden.yml) — macOS skips this tag via dart_test.yaml, so
// no goldens are authored or verified locally in this pass.
//
// THIS PASS (red): `ReadmeBody.headerCrop()` still renders `SizedBox.shrink`
// (zero size). Forcing this suite locally
// (`flutter test --tags golden --run-skipped`) fails with "Invalid image
// dimensions" — `toImage` cannot rasterize a zero-pixel layer — rather than a
// pixel diff. That is the correct red for a golden of a not-yet-implemented
// widget; the green pass's real header/collaboration/about tree gives the
// scene non-zero size and lets `matchesGoldenFile` run for real (still
// missing a baseline until Linux CI authors one — see the workflow above).
void main() {
  group('ReadmeBody.headerCrop golden', () {
    testWidgets('en · desktop 1000', (tester) async {
      await pumpGoldenSection(
        tester,
        section: const ReadmeBody.headerCrop(),
        surface: const Size(1000, 900),
      );
      await expectLater(
        find.byType(ReadmeBody),
        matchesGoldenFile('goldens/readme_header_en_desktop.png'),
      );
    });

    testWidgets('en · phone 390', (tester) async {
      await pumpGoldenSection(
        tester,
        section: const ReadmeBody.headerCrop(),
        surface: const Size(390, 1100),
      );
      await expectLater(
        find.byType(ReadmeBody),
        matchesGoldenFile('goldens/readme_header_en_phone.png'),
      );
    });
  });
}
