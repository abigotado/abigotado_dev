import 'package:abigotado_dev/src/app/theme/app_theme.dart';
import 'package:abigotado_dev/src/features/readme/state/presentation_notifier.dart';
import 'package:abigotado_dev/src/features/readme/widget/readme_entry_chip.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helper: pump ReadmeEntryChip under MaterialApp home Scaffold so a root
// ModalRoute exists (openReadme's LocalHistoryEntry needs a route to attach
// to).
// ---------------------------------------------------------------------------

Future<ProviderContainer> _pumpChip(
  WidgetTester tester, {
  Size surface = const Size(800, 600),
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final container = ProviderContainer();
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: ReadmeEntryChip()),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return container;
}

void main() {
  group('ReadmeEntryChip', () {
    group('rendering', () {
      testWidgets('renders l10n.rm_entry_chip', (tester) async {
        await _pumpChip(tester);
        final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));

        expect(find.text(l10n.rm_entry_chip), findsOneWidget);
      });
    });

    group('tap', () {
      testWidgets('tap sets readmeOpenProvider to true', (tester) async {
        final container = await _pumpChip(tester);
        final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));

        expect(container.read(readmeOpenProvider), isFalse);

        await tester.tap(find.text(l10n.rm_entry_chip));
        await tester.pumpAndSettle();

        expect(container.read(readmeOpenProvider), isTrue);
      });
    });

    group('tap target', () {
      testWidgets('rendered height is at least 44 px', (tester) async {
        await _pumpChip(tester);

        final size = tester.getSize(find.byType(ReadmeEntryChip));
        expect(
          size.height,
          greaterThanOrEqualTo(44),
          reason:
              'WCAG 2.5.5: minimum tap target height must be at least 44 '
              'px; actual height: ${size.height}',
        );
      });
    });
  });
}
