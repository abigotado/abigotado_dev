import 'package:abigotado_dev/src/app/theme/app_theme.dart';
import 'package:abigotado_dev/src/app/widget/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// SectionCard is shared chrome that PubspecCard and ChangelogCard both depend
// on. These tests pin the contract those cards rely on: the title/badge/child
// render, and — load-bearing for the two cards' opposite a11y treatments — the
// shell stays a11y-neutral (it must NOT introduce an ExcludeSemantics of its
// own, or pubspec would double-exclude and the changelog prose would wrongly
// vanish from the semantics tree).

Future<void> _pumpCard(
  WidgetTester tester, {
  required Widget child,
  String title = 'pubspec.yaml',
  String badge = 'skills',
  Size surface = const Size(800, 600),
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: Scaffold(
        body: Center(
          child: SectionCard(title: title, badge: badge, child: child),
        ),
      ),
    ),
  );
}

void main() {
  group('SectionCard', () {
    testWidgets('renders the title, the badge, and the child', (tester) async {
      await _pumpCard(tester, child: const Text('BODY-CONTENT'));

      expect(find.text('pubspec.yaml'), findsOneWidget);
      expect(find.text('skills'), findsOneWidget);
      expect(find.text('BODY-CONTENT'), findsOneWidget);
    });

    testWidgets(
      'is a11y-neutral: introduces no ExcludeSemantics and leaves the '
      'child reachable to assistive tech',
      (tester) async {
        final handle = tester.ensureSemantics();

        await _pumpCard(tester, child: const Text('READABLE-BODY'));

        // The shell must own no ExcludeSemantics in its OWN subtree — consumers
        // add their own (pubspec excludes its code body; changelog stays
        // readable). Scoped to SectionCard so framework chrome doesn't count.
        expect(
          find.descendant(
            of: find.byType(SectionCard),
            matching: find.byType(ExcludeSemantics),
          ),
          findsNothing,
        );
        // The child's content is genuinely in the semantics tree.
        expect(find.bySemanticsLabel('READABLE-BODY'), findsOneWidget);

        handle.dispose();
      },
    );

    testWidgets(
      'narrow 320px with an over-long title and badge does not overflow',
      (tester) async {
        await _pumpCard(
          tester,
          title: 'an-absurdly-long-filename-that-would-overflow.yaml',
          badge: 'an-absurdly-long-badge-label-too',
          surface: const Size(320, 600),
          child: const Text('x'),
        );

        // Flexible + ellipsis on both header texts keep the row in bounds.
        expect(tester.takeException(), isNull);
      },
    );
  });
}
