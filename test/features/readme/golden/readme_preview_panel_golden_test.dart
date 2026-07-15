@Tags(['golden'])
library;

import 'package:abigotado_dev/src/features/readme/widget/readme_preview_panel.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../golden/golden_harness.dart';

// Golden tests run on Linux CI only (tag `golden`, skipped by default). They
// catch pixel regressions the structural widget tests can't see — the
// panel's header-strip chrome, headerCrop content, and CTA styling at its
// real fixed width.
//
// The panel is pumped BARE — no external width wrapper — deliberately: an
// external SizedBox/width wrapper around ReadmePreviewPanel would defeat the
// exact "reclaim its own width" mechanism its own class doc describes
// (EditorShell must never add one either), so wrapping it here would golden
// a layout the widget is never actually placed in production. Under
// `pumpGoldenSection`'s SingleChildScrollView the widget receives loose (not
// tight) cross-axis constraints, so its own `Container(width:
// AppSizing.readmePanelWidth, ...)` sizes it correctly once implemented,
// exactly as it will inside EditorShell's real Row.
//
// THIS PASS (red): `ReadmePreviewPanel.build` still returns `SizedBox.shrink`
// unconditionally (zero size), and — because it is pumped bare under those
// loose constraints — it renders at true zero size. Forcing this suite
// locally (`flutter test --tags golden --run-skipped`) fails with "Invalid
// image dimensions" — `toImage` cannot rasterize a zero-pixel layer — rather
// than a pixel diff. That is the correct red for a golden of a
// not-yet-implemented widget, mirroring readme_view_golden_test.dart's
// stub-red precedent. The green pass's real
// `Container(width: AppSizing.readmePanelWidth, ...)` gives the scene
// non-zero size and lets `matchesGoldenFile` run for real (still missing a
// baseline until Linux CI authors one — see the workflow above).
void main() {
  group('ReadmePreviewPanel golden', () {
    testWidgets('en · 420 surface', (tester) async {
      await pumpGoldenSection(
        tester,
        section: const ReadmePreviewPanel(),
        surface: const Size(420, 950),
      );
      await expectLater(
        find.byType(ReadmePreviewPanel),
        matchesGoldenFile('goldens/readme_panel_en.png'),
      );
    });
  });
}
