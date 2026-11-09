import 'package:abigotado_dev/src/app/theme/app_theme.dart';
import 'package:abigotado_dev/src/app/widget/contact_link_tile.dart';
import 'package:abigotado_dev/src/features/cta/widget/contacts_panel.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContactsPanel', () {
    group('layout', () {
      testWidgets('wider than its chips → chips centre in the panel', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(1000, 600));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('en'),
              home: const Scaffold(
                body: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(width: 900, child: ContactsPanel()),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final chips = find.byType(ContactLinkTile);
        final left = tester.getTopLeft(chips.first).dx;
        final right = tester.getTopRight(chips.last).dx;
        expect((left + right) / 2, closeTo(450, 0.5));
      });
    });
  });
}
