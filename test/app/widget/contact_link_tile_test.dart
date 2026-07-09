import 'package:abigotado_dev/src/app/theme/app_theme.dart';
import 'package:abigotado_dev/src/app/widget/contact_link_tile.dart';
import 'package:abigotado_dev/src/core/content/contact_link.dart';
import 'package:abigotado_dev/src/core/launcher/url_launcher.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Recording fake launcher — injected via ProviderScope override.
// Never calls the real platform; records every opened Uri.
// ---------------------------------------------------------------------------

final class _RecordingUrlLauncher implements UrlLauncher {
  final opened = <Uri>[];

  @override
  Future<void> open(Uri url) async => opened.add(url);
}

// ---------------------------------------------------------------------------
// Helper: pump a single ContactLinkTile in a minimal Material/l10n tree.
// ---------------------------------------------------------------------------

Future<_RecordingUrlLauncher> _pumpTile(
  WidgetTester tester, {
  required ContactLink link,
  Size surface = const Size(800, 600),
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final fake = _RecordingUrlLauncher();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [urlLauncherProvider.overrideWithValue(fake)],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(child: ContactLinkTile(link: link)),
        ),
      ),
    ),
  );
  await tester.pump();

  return fake;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ContactLinkTile', () {
    // -----------------------------------------------------------------------
    // Tap wiring — verifies the tile opens the correct URL via the launcher.
    // Catches a wrong-url / wrong-parse wiring bug.
    // -----------------------------------------------------------------------
    group('tap', () {
      testWidgets('tap opens the right url — GitHub tile', (tester) async {
        const link = ContactLink(
          label: 'GitHub',
          url: 'https://github.com/Abigotado',
        );

        final fake = await _pumpTile(tester, link: link);

        await tester.tap(find.byType(ContactLinkTile));
        await tester.pump();

        expect(
          fake.opened,
          hasLength(1),
          reason: 'tap must trigger exactly one open call',
        );
        expect(
          fake.opened.single,
          equals(Uri.parse('https://github.com/Abigotado')),
          reason: 'tap must open the GitHub URL, not some other URI',
        );
      });

      testWidgets('tap opens the right url — mailto tile', (tester) async {
        const link = ContactLink(
          label: 'Email',
          url: 'mailto:nik.koval.89@gmail.com',
        );

        final fake = await _pumpTile(tester, link: link);

        await tester.tap(find.byType(ContactLinkTile));
        await tester.pump();

        expect(
          fake.opened.single,
          equals(Uri.parse('mailto:nik.koval.89@gmail.com')),
        );
      });
    });

    // -----------------------------------------------------------------------
    // Tap target size — WCAG 2.5.5 minimum 44 × 44 dp.
    // -----------------------------------------------------------------------
    group('tap target', () {
      testWidgets('rendered height is at least 44 px', (tester) async {
        const link = ContactLink(
          label: 'GitHub',
          url: 'https://github.com/Abigotado',
        );

        await _pumpTile(tester, link: link);

        final size = tester.getSize(find.byType(ContactLinkTile));
        expect(
          size.height,
          greaterThanOrEqualTo(44),
          reason:
              'WCAG 2.5.5: minimum tap target height must be at least 44 px; '
              'actual height: ${size.height}',
        );
      });
    });

    // -----------------------------------------------------------------------
    // Accessibility — tile must be announced as a button-link with its label.
    // -----------------------------------------------------------------------
    group('a11y', () {
      testWidgets(
        'tile exposes semantics node: isButton, isLink flags and label',
        (tester) async {
          final handle = tester.ensureSemantics();

          const link = ContactLink(
            label: 'GitHub',
            url: 'https://github.com/Abigotado',
          );

          await _pumpTile(tester, link: link);

          final node = tester.getSemantics(find.byType(ContactLinkTile));
          final data = node.getSemanticsData();

          expect(
            data.flagsCollection.isButton,
            isTrue,
            reason: 'ContactLinkTile must expose isButton semantic flag',
          );
          expect(
            data.flagsCollection.isLink,
            isTrue,
            reason: 'ContactLinkTile must expose isLink semantic flag',
          );
          expect(
            node.label,
            contains('GitHub'),
            reason:
                'ContactLinkTile semantics label must contain the link label',
          );

          handle.dispose();
        },
      );
    });
  });
}
