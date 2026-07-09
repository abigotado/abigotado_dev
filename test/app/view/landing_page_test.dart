import 'package:abigotado_dev/src/app/theme/app_theme.dart';
import 'package:abigotado_dev/src/app/view/landing_page.dart';
import 'package:abigotado_dev/src/app/widget/editor_file.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/core/effects/effects_store.dart';
import 'package:abigotado_dev/src/features/cta/widget/merge_cta_section.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/features/hero/view/terminal_hero.dart';
import 'package:abigotado_dev/src/features/readme/widget/readme_entry_chip.dart';
import 'package:abigotado_dev/src/features/readme/widget/readme_invitation_card.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake — lite effects mode so TerminalHero calls skip() synchronously and
// pumpAndSettle is safe (no perpetual spinner/cursor controllers).
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
// Helper: pump LandingPage in a Scaffold + SingleChildScrollView so it lays
// out at intrinsic height without overflow — mirrors how EditorScrollHost
// pumps it (SingleChildScrollView(child: LandingPage(sectionKeys: ...))).
// ---------------------------------------------------------------------------

Future<void> _pumpLanding(
  WidgetTester tester, {
  required Size surface,
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: LandingPage(
              sectionKeys: {
                for (final f in EditorFile.values) f: GlobalKey(),
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('LandingPage', () {
    for (final width in [360.0, 1000.0]) {
      group('width $width', () {
        testWidgets(
          'ReadmeEntryChip is present and its text renders before '
          'TerminalHero (top dy < TerminalHero top dy)',
          (tester) async {
            await _pumpLanding(tester, surface: Size(width, 3000));
            final l10n = AppLocalizations.of(
              tester.element(find.byType(Scaffold)),
            );

            expect(find.byType(ReadmeEntryChip), findsOneWidget);

            final chipTextDy = tester
                .getTopLeft(find.text(l10n.rm_entry_chip))
                .dy;
            final heroDy = tester.getTopLeft(find.byType(TerminalHero)).dy;

            expect(
              chipTextDy,
              lessThan(heroDy),
              reason:
                  'ReadmeEntryChip must be the first rendered content, '
                  'above TerminalHero',
            );
          },
        );

        // Passes on stub — must STAY green. ReadmeInvitationCard mounts as
        // SizedBox.shrink in this pass, but its Column slot (after the
        // contacts KeyedSubtree, before the FAB-clearance SizedBox) is real
        // production code already in LandingPage — getTopLeft on the shrunk
        // box still reports its true layout position, so this is a real
        // ordering guard, not a vacuous one.
        testWidgets(
          'ReadmeInvitationCard is present and below MergeCtaSection '
          '(MergeCtaSection top dy < invitation top dy)',
          (tester) async {
            await _pumpLanding(tester, surface: Size(width, 3000));

            expect(find.byType(ReadmeInvitationCard), findsOneWidget);

            final ctaDy = tester.getTopLeft(find.byType(MergeCtaSection)).dy;
            final invitationDy = tester
                .getTopLeft(find.byType(ReadmeInvitationCard))
                .dy;

            expect(
              ctaDy,
              lessThan(invitationDy),
              reason: 'ReadmeInvitationCard must render below MergeCtaSection',
            );
          },
        );
      });
    }
  });
}
