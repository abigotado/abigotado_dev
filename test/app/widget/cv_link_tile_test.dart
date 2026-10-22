import 'package:abigotado_dev/src/app/theme/app_theme.dart';
import 'package:abigotado_dev/src/app/widget/cv_link_tile.dart';
import 'package:abigotado_dev/src/core/content/cv_document.dart';
import 'package:abigotado_dev/src/core/launcher/url_launcher.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class _RecordingUrlLauncher implements UrlLauncher {
  final opened = <Uri>[];

  @override
  Future<void> open(Uri url) async => opened.add(url);
}

Future<_RecordingUrlLauncher> _pumpTile(
  WidgetTester tester, {
  required Locale locale,
}) async {
  final fake = _RecordingUrlLauncher();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [urlLauncherProvider.overrideWithValue(fake)],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: Center(child: CvLinkTile())),
      ),
    ),
  );
  await tester.pump();

  return fake;
}

void main() {
  group('CvLinkTile', () {
    group('tap', () {
      final cases = {
        const Locale('ru'): cvPdfRuUrl,
        const Locale('en'): cvPdfEnUrl,
        const Locale('es'): cvPdfEnUrl,
      };

      for (final MapEntry(key: locale, value: url) in cases.entries) {
        testWidgets('$locale opens $url', (tester) async {
          final fake = await _pumpTile(tester, locale: locale);

          await tester.tap(find.byType(CvLinkTile));
          await tester.pump();

          expect(fake.opened, equals([Uri.parse(url)]));
        });
      }
    });

    group('label', () {
      testWidgets('shows the active locale cv_pdf label', (tester) async {
        await _pumpTile(tester, locale: const Locale('ru'));

        final l10n = await AppLocalizations.delegate.load(const Locale('ru'));
        expect(find.text(l10n.cv_pdf), findsOneWidget);
      });

      testWidgets('es label flags the English-only PDF', (tester) async {
        await _pumpTile(tester, locale: const Locale('es'));

        final es = await AppLocalizations.delegate.load(const Locale('es'));
        final en = await AppLocalizations.delegate.load(const Locale('en'));
        expect(
          es.cv_pdf,
          isNot(equals(en.cv_pdf)),
          reason: 'es serves the English PDF, so its label must say so',
        );
        expect(find.text(es.cv_pdf), findsOneWidget);
      });
    });
  });
}
