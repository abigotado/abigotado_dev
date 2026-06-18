import 'package:abigotado_dev/src/app/theme/app_sizing.dart';
import 'package:abigotado_dev/src/app/widget/content_width.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helper: a key for the probe child so we can measure it after layout.
// ---------------------------------------------------------------------------

const _probeKey = Key('content-width-probe');

// ---------------------------------------------------------------------------
// Helper: pump ContentWidth at a fixed surface with a height-bounded child
// that tries to be as wide as its parent allows.
// ---------------------------------------------------------------------------

Future<void> _pumpContentWidth(
  WidgetTester tester, {
  required Size surfaceSize,
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: ContentWidth(
          // ConstrainedBox.expand attempts to fill all available width/height;
          // the fixed height keeps it from being unconstrained vertically.
          child: ConstrainedBox(
            key: _probeKey,
            constraints: const BoxConstraints.expand(height: 10),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ContentWidth', () {
    group('width cap on wide surface', () {
      testWidgets(
        'surface 1280×800 → child width equals contentMaxWidth minus '
        '2×contentGutter (952)',
        (tester) async {
          await _pumpContentWidth(tester, surfaceSize: const Size(1280, 800));

          final childSize = tester.getSize(find.byKey(_probeKey));

          const expected =
              AppSizing.contentMaxWidth - 2 * AppSizing.contentGutter;
          // RED: passthrough stub lets child fill 1280; capped width is 952.
          expect(
            childSize.width,
            equals(expected),
            reason:
                'ContentWidth must cap child to '
                '${AppSizing.contentMaxWidth} − 2×${AppSizing.contentGutter} '
                '= $expected px on a 1280 px surface',
          );
        },
      );
    });

    group('left-alignment on wide surface', () {
      testWidgets(
        'surface 1280×800 → child left edge is at contentGutter (24), '
        'not centered',
        (tester) async {
          await _pumpContentWidth(tester, surfaceSize: const Size(1280, 800));

          final topLeft = tester.getTopLeft(find.byKey(_probeKey));

          // RED: passthrough stub left-aligns to 0; centered would be ~164.
          // The green contract left-aligns inside the gutter padding, so dx
          // should be exactly AppSizing.contentGutter.
          expect(
            topLeft.dx,
            equals(AppSizing.contentGutter),
            reason:
                'ContentWidth must left-align with a '
                '${AppSizing.contentGutter} px gutter; '
                'dx was ${topLeft.dx}, expected '
                '${AppSizing.contentGutter}',
          );
        },
      );
    });

    group('fills width below token width', () {
      testWidgets(
        'surface 360×800 → child width equals 360 minus 2×contentGutter (312)',
        (tester) async {
          await _pumpContentWidth(tester, surfaceSize: const Size(360, 800));

          final childSize = tester.getSize(find.byKey(_probeKey));

          const expected = 360 - 2 * AppSizing.contentGutter;
          // RED: passthrough gives 360; correct width after gutters is 312.
          expect(
            childSize.width,
            equals(expected),
            reason:
                'on a 360 px surface ContentWidth must fill to '
                '360 − 2×${AppSizing.contentGutter} = $expected px',
          );
        },
      );
    });
  });
}
