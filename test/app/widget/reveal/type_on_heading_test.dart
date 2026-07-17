import 'package:abigotado_dev/src/app/widget/reveal/section_build_scope.dart';
import 'package:abigotado_dev/src/app/widget/reveal/type_on_heading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// TypeOnHeading has zero Riverpod/effects dependency — SectionBuildScope is a
// plain InheritedWidget — so these harnesses need no ProviderScope, mirroring
// the widget's own zero-ceremony contract.
//
// The "animated branch" (SectionBuildScope present) is unreachable in the
// CONTRACTS pass: `_AnimatedHeading.build` throws UnimplementedError
// unconditionally, regardless of the `progress` value passed in — so every
// scoped test below is RED for the same underlying reason. The "static
// branch" (no scope) test is BORN-GREEN — it pins the a11y-neutral bare-Text
// render that `SectionCard`/`section_card_test.dart` already depend on.
// ---------------------------------------------------------------------------

const String _fullText = 'CHANGELOG.md';
const TextStyle _style = TextStyle(fontFamily: 'monospace', fontSize: 13);

Future<void> _pumpBare(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: TypeOnHeading(text: _fullText, style: _style),
        ),
      ),
    ),
  );
}

Future<void> _pumpScoped(WidgetTester tester, double progress) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: SectionBuildScope(
            progress: AlwaysStoppedAnimation<double>(progress),
            child: const TypeOnHeading(text: _fullText, style: _style),
          ),
        ),
      ),
    ),
  );
}

/// The [TextSpan] rendered by the (sole) [Text] beneath [TypeOnHeading],
/// read structurally — never by pixels. Works for the animated `Text.rich`
/// branch, whose `.textSpan` is a real [TextSpan]; deliberately does not name
/// the not-yet-implemented cursor glyph type (see the class doc's "Intended
/// GREEN render" sketch) — a bare [WidgetSpan] child is the structural marker
/// the contract itself suggests for "a cursor is embedded here".
TextSpan _headingSpan(WidgetTester tester) =>
    tester
            .widget<Text>(
              find.descendant(
                of: find.byType(TypeOnHeading),
                matching: find.byType(Text),
              ),
            )
            .textSpan!
        as TextSpan;

String _visibleText(TextSpan span) =>
    span.children!.whereType<TextSpan>().map((s) => s.text ?? '').join();

bool _hasCursorSpan(TextSpan span) =>
    span.children?.any((child) => child is WidgetSpan) ?? false;

void main() {
  group('TypeOnHeading', () {
    group('static branch (no SectionBuildScope)', () {
      testWidgets(
        // Passes on stub — must STAY green: pins the a11y-neutral bare-Text
        // render section_card_test.dart already relies on.
        'bare text renders verbatim, with no Semantics/ExcludeSemantics '
        'wrapper of its own',
        (tester) async {
          await _pumpBare(tester);

          expect(find.text(_fullText), findsOneWidget);
          expect(
            find.descendant(
              of: find.byType(TypeOnHeading),
              matching: find.byType(Semantics),
            ),
            findsNothing,
            reason:
                'the static branch must be a bare Text — no Semantics '
                'wrapper of its own',
          );
          expect(
            find.descendant(
              of: find.byType(TypeOnHeading),
              matching: find.byType(ExcludeSemantics),
            ),
            findsNothing,
            reason:
                'the static branch must be a bare Text — no '
                'ExcludeSemantics wrapper of its own',
          );
        },
      );
    });

    group('animated branch (SectionBuildScope present)', () {
      group('v=0', () {
        testWidgets(
          'full text is the semantics label from frame 1; visible text is '
          'not yet the full string',
          (tester) async {
            final handle = tester.ensureSemantics();

            await _pumpScoped(tester, 0);

            expect(
              find.bySemanticsLabel(_fullText),
              findsOneWidget,
              reason:
                  'an assistive-tech user must get the complete heading '
                  'from frame 1 — screen readers never wait for the '
                  'type-out',
            );
            expect(
              find.text(_fullText),
              findsNothing,
              reason:
                  'at v=0 no characters have typed yet — the full '
                  'string must not be the VISIBLE text',
            );

            handle.dispose();
          },
        );
      });

      group('v=0.25 (inside the heading window)', () {
        testWidgets(
          'partial glyphs are shown and a cursor span is present',
          (tester) async {
            await _pumpScoped(tester, 0.25);

            final span = _headingSpan(tester);
            expect(
              _visibleText(span).length,
              lessThan(_fullText.length),
              reason:
                  'mid-typing must show fewer than the full character '
                  'count',
            );
            expect(
              _hasCursorSpan(span),
              isTrue,
              reason:
                  'the cursor must be visible while typing is still in '
                  'progress',
            );
          },
        );
      });

      group('v=1', () {
        testWidgets('visible text equals the full string, no cursor span', (
          tester,
        ) async {
          await _pumpScoped(tester, 1);

          final span = _headingSpan(tester);
          expect(_visibleText(span), equals(_fullText));
          expect(
            _hasCursorSpan(span),
            isFalse,
            reason: 'the cursor must disappear the instant typing completes',
          );
        });
      });

      group('height stability', () {
        testWidgets(
          'rendered height is identical at v=0, 0.25, 0.5, and 1 — the '
          'cursor must fit the line box (a growing header would shift '
          'every section below)',
          (tester) async {
            final heights = <double, double>{};
            for (final v in [0.0, 0.25, 0.5, 1.0]) {
              await _pumpScoped(tester, v);
              heights[v] = tester.getSize(find.byType(TypeOnHeading)).height;
            }

            final settled = heights[1.0];
            for (final v in [0.0, 0.25, 0.5]) {
              expect(
                heights[v],
                equals(settled),
                reason:
                    'height at v=$v (${heights[v]}) must match the '
                    'settled height ($settled)',
              );
            }
          },
        );
      });
    });
  });
}
