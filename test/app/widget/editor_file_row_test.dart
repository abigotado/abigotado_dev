import 'package:abigotado_dev/src/app/widget/editor_file.dart';
import 'package:abigotado_dev/src/app/widget/editor_file_row.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helper: pump an EditorFileRow inside a minimal Material + l10n tree.
//
// The l10n delegates are required for EditorFile.label(l10n).
// The Scaffold provides a Material ancestor for the future InkWell tap target.
// ---------------------------------------------------------------------------

Future<void> _pumpRow(
  WidgetTester tester, {
  required bool selected,
  required EditorFile file,
  VoidCallback? onTap,
  Locale locale = const Locale('en'),
}) async {
  await tester.binding.setSurfaceSize(const Size(300, 80));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: EditorFileRow(file: file, selected: selected, onTap: onTap),
      ),
    ),
  );
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('EditorFileRow', () {
    // -------------------------------------------------------------------------
    group('selected', () {
      // The green pass adds Semantics(selected: true) and highlight styling.
      // Until then the build has no such semantics node.
      testWidgets(
        'selected:true emits the isSelected semantics flag',
        (tester) async {
          // Dispose the handle in-body (not via addTearDown): the framework's
          // end-of-test semantics-handle verification runs before tearDowns.
          final handle = tester.ensureSemantics();

          await _pumpRow(
            tester,
            selected: true,
            file: EditorFile.pubspec,
          );

          // The row must carry SemanticsFlag.isSelected so assistive technology
          // can report which file is active. Fails until the green pass adds
          // Semantics(selected: true, ...) around the row.
          //
          // isSemantics (subset match) is used rather than matchesSemantics
          // (whole-node match): the active row is also a button (isButton) and
          // carries a label, so a strict whole-node assertion would reject
          // those unrelated flags. This test only pins the one property it is
          // named for — that the row is selected.
          expect(
            tester.getSemantics(find.byType(EditorFileRow)),
            isSemantics(isSelected: true),
          );

          handle.dispose();
        },
      );
    });

    // -------------------------------------------------------------------------
    group('onTap', () {
      testWidgets(
        'tapping the row invokes onTap',
        (tester) async {
          var tapped = false;

          await _pumpRow(
            tester,
            selected: false,
            file: EditorFile.pubspec,
            onTap: () => tapped = true,
          );

          await tester.tap(find.byType(EditorFileRow));
          await tester.pump();

          // Fails until the green pass wraps the row in an InkWell or
          // GestureDetector that routes taps to the onTap callback.
          expect(tapped, isTrue);
        },
      );
    });
  });
}
