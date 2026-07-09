import 'package:abigotado_dev/src/app/theme/app_theme.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/core/effects/effects_store.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/features/readme/view/readme_view.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake — lite effects.
// ---------------------------------------------------------------------------

final class _LiteEffectsStore implements EffectsStore {
  const _LiteEffectsStore();

  @override
  EffectsMode? read() => EffectsMode.lite;

  @override
  Future<void> write(EffectsMode mode) async {}

  @override
  Future<void> clear() async {}
}

// ---------------------------------------------------------------------------
// Helper: pump ReadmeView inside a full l10n/theme/effects harness.
// ---------------------------------------------------------------------------

Future<void> _pumpView(
  WidgetTester tester, {
  Size surface = const Size(1000, 800),
  Locale locale = const Locale('en'),
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        effectsStoreProvider.overrideWithValue(const _LiteEffectsStore()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: ReadmeView()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ReadmeView', () {
    group('tab', () {
      testWidgets('tab row renders l10n.rm_tab_title (README.md)', (
        tester,
      ) async {
        await _pumpView(tester);
        final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));

        expect(find.text(l10n.rm_tab_title), findsOneWidget);
      });

      testWidgets(
        '✕ close control exists via bySemanticsLabel(l10n.rm_close_hint)',
        (tester) async {
          await _pumpView(tester);
          final l10n = AppLocalizations.of(
            tester.element(find.byType(Scaffold)),
          );

          expect(
            find.bySemanticsLabel(l10n.rm_close_hint),
            findsOneWidget,
          );
        },
      );
    });

    group('anchor bar', () {
      testWidgets('4 anchor chips render', (tester) async {
        await _pumpView(tester);
        final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));

        expect(find.text(l10n.rm_anchor_experience), findsOneWidget);
        expect(find.text(l10n.rm_anchor_skills), findsOneWidget);
        expect(find.text(l10n.rm_anchor_education), findsOneWidget);
        expect(find.text(l10n.rm_anchor_contacts), findsOneWidget);
      });
    });

    group('animation', () {
      testWidgets(
        'no transient callbacks after pumpAndSettle (static in stage 1)',
        (tester) async {
          await _pumpView(tester);

          expect(
            tester.binding.transientCallbackCount,
            equals(0),
            reason:
                'ReadmeView schedules no ticker of its own — the anchor bar '
                'has no active-highlight animation in stage 1',
          );
        },
      );
    });

    group('anchor tap', () {
      testWidgets(
        'tapping an anchor chip in lite mode jumps the target section into '
        'view without exception',
        (tester) async {
          await _pumpView(tester);
          final l10n = AppLocalizations.of(
            tester.element(find.byType(Scaffold)),
          );

          final contactsChip = find.text(l10n.rm_anchor_contacts);
          expect(contactsChip, findsOneWidget);

          await tester.tap(contactsChip);
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        },
      );
    });
  });
}
