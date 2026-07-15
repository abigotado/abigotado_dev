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
// The panel is wrapped in a HEIGHT-ONLY SizedBox — width stays the panel's
// own (its `Container(width: AppSizing.readmePanelWidth)`), so the golden
// still exercises the self-sizing the class doc describes and that
// EditorShell relies on. The height bound is required by the harness:
// `pumpGoldenSection` hosts the section inside a SingleChildScrollView
// (unbounded height), and the panel's root Column carries an `Expanded`
// scroll body — under unbounded height that is a RenderFlex error and the
// scene can never rasterize. Bounding height only (never width) keeps the
// reclaim invariant intact while making the baseline authorable.
// (readme_view_golden_test.dart needs no such bound because it goldens
// ReadmeBody.headerCrop — a mainAxisSize.min Column with no Expanded.)
void main() {
  group('ReadmePreviewPanel golden', () {
    testWidgets('en · 420 surface', (tester) async {
      await pumpGoldenSection(
        tester,
        section: const SizedBox(height: 900, child: ReadmePreviewPanel()),
        surface: const Size(420, 950),
      );
      await expectLater(
        find.byType(ReadmePreviewPanel),
        matchesGoldenFile('goldens/readme_panel_en.png'),
      );
    });
  });
}
