import 'package:abigotado_dev/src/app/theme/app_theme.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/core/effects/effects_store.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/features/readme/view/readme_body.dart';
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

        // Each anchor word also appears as its section heading (a deliberate
        // nav-word/heading-word echo), so the finder scopes to the tappable
        // chip: the InkWell is the only interactive bearer of the word.
        expect(
          find.widgetWithText(InkWell, l10n.rm_anchor_experience),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(InkWell, l10n.rm_anchor_skills),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(InkWell, l10n.rm_anchor_education),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(InkWell, l10n.rm_anchor_contacts),
          findsOneWidget,
        );
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
        'lite mode: the education anchor jumps its section to the viewport '
        'top; the contacts anchor lands within the viewport (clamped)',
        (tester) async {
          await _pumpView(tester);
          final l10n = AppLocalizations.of(
            tester.element(find.byType(Scaffold)),
          );

          // Chip finders scope to the InkWell wrapper — the same words also
          // render as section headings inside the document body; heading
          // finders scope to ReadmeBody (the chips live in the anchor bar
          // outside it).
          final educationChip = find.widgetWithText(
            InkWell,
            l10n.rm_anchor_education,
          );
          final educationHeading = find.descendant(
            of: find.byType(ReadmeBody),
            matching: find.text(l10n.rm_h_education),
          );
          expect(educationChip, findsOneWidget);

          // Precondition: education starts below the 800 px fold, otherwise
          // this test cannot prove the jump happened.
          expect(tester.getTopLeft(educationHeading).dy, greaterThan(800));

          await tester.tap(educationChip);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Lite mode = instant jumpTo. Education is a MID-document section,
          // so ensureVisible can align its top with the viewport top — the
          // heading must sit near the top of the pane, not be nudged a few
          // pixels.
          final educationTop = tester.getTopLeft(educationHeading).dy;
          expect(
            educationTop,
            lessThan(400),
            reason:
                'after the education anchor tap its section must be at the '
                'top of the pane (was at dy=$educationTop)',
          );

          // The contacts section is the LAST section: aligning its top with
          // the viewport top would overshoot maxScrollExtent, so the jump
          // clamps at the document bottom. The heading must still land
          // inside the viewport.
          final contactsChip = find.widgetWithText(
            InkWell,
            l10n.rm_anchor_contacts,
          );
          final contactsHeading = find.descendant(
            of: find.byType(ReadmeBody),
            matching: find.text(l10n.rm_h_contacts),
          );

          await tester.tap(contactsChip);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          final contactsTop = tester.getTopLeft(contactsHeading).dy;
          expect(
            contactsTop,
            lessThan(800),
            reason:
                'after the contacts anchor tap the section must be visible '
                'within the 800 px viewport (was at dy=$contactsTop; the '
                'scroll clamps at maxScrollExtent because contacts is the '
                'final section)',
          );
        },
      );
    });
  });
}
