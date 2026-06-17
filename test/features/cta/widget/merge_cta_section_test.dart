import 'package:abigotado_dev/src/app/theme/app_theme.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/core/effects/effects_store.dart';
import 'package:abigotado_dev/src/features/cta/widget/contacts_panel.dart';
import 'package:abigotado_dev/src/features/cta/widget/merge_button.dart';
import 'package:abigotado_dev/src/features/cta/widget/merge_cta_section.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake effects store — returns a fixed stored mode; writes/clears are no-ops.
// Mirrors the harness from terminal_hero_test.dart.
// ---------------------------------------------------------------------------

final class _FakeEffectsStore implements EffectsStore {
  const _FakeEffectsStore({this.stored});

  final EffectsMode? stored;

  @override
  EffectsMode? read() => stored;

  @override
  Future<void> write(EffectsMode mode) async {}

  @override
  Future<void> clear() async {}
}

// ---------------------------------------------------------------------------
// Helper: pump MergeCtaSection in a minimal Material/l10n tree.
//
// [effectsStore] forces the effects mode; [locale] defaults to en.
// Surface is set to 800×900 by default; pass [surface] to override.
// addTearDown resets the surface so tests don't pollute each other.
// ---------------------------------------------------------------------------

Future<void> _pumpSection(
  WidgetTester tester, {
  required EffectsStore effectsStore,
  Locale locale = const Locale('en'),
  Size surface = const Size(800, 900),
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [effectsStoreProvider.overrideWithValue(effectsStore)],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: MergeCtaSection()),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('MergeCtaSection', () {
    // -----------------------------------------------------------------------
    // GREEN: idle state renders correctly before any tap.
    // These pass even with the no-op stub.
    // -----------------------------------------------------------------------
    group('idle state', () {
      testWidgets(
        'idle renders the merge command literal and checks line',
        (tester) async {
          await _pumpSection(
            tester,
            effectsStore: const _FakeEffectsStore(stored: EffectsMode.lite),
          );
          await tester.pump();

          // The merge command must be rendered.
          expect(
            find.textContaining('Merge nikita into your-project/main'),
            findsOneWidget,
            reason: 'idle MergeButton must show the merge command literal',
          );

          // The checks line must be rendered.
          expect(
            find.text(
              'checks passed · reviewer approved · 0 conflicts',
            ),
            findsOneWidget,
            reason: 'MergeButton must always show the checks line',
          );
        },
      );

      testWidgets(
        'idle — no contacts heading visible before tap',
        (tester) async {
          await _pumpSection(
            tester,
            effectsStore: const _FakeEffectsStore(stored: EffectsMode.lite),
          );
          await tester.pump();

          final l10n = AppLocalizations.of(
            tester.element(find.byType(MergeCtaSection)),
          );

          expect(
            find.text(l10n.cta_heading),
            findsNothing,
            reason: 'contacts heading must not appear in idle state',
          );
        },
      );

      testWidgets(
        'lite mount, no tap — no contacts, no ticker',
        (tester) async {
          await _pumpSection(
            tester,
            effectsStore: const _FakeEffectsStore(stored: EffectsMode.lite),
          );
          await tester.pump();

          expect(
            tester.binding.transientCallbackCount,
            equals(0),
            reason: 'lite mode must not allocate any animation tickers at idle',
          );

          expect(
            find.byType(ContactsPanel),
            findsNothing,
            reason: 'ContactsPanel must not appear before tap',
          );
        },
      );

      testWidgets(
        'full mount, no tap — no ticker (lazy controller)',
        (tester) async {
          await _pumpSection(
            tester,
            effectsStore: const _FakeEffectsStore(stored: EffectsMode.full),
          );
          // Single pump only — a running controller would hang pumpAndSettle.
          await tester.pump();

          expect(
            tester.binding.transientCallbackCount,
            equals(0),
            reason:
                'full mode must not pre-allocate an AnimationController '
                'until the button is tapped (lazy controller)',
          );
        },
      );

      testWidgets(
        '320 px narrow layout — no overflow exception',
        (tester) async {
          await _pumpSection(
            tester,
            effectsStore: const _FakeEffectsStore(stored: EffectsMode.lite),
            surface: const Size(320, 900),
          );
          await tester.pump();

          expect(
            tester.takeException(),
            isNull,
            reason: 'MergeCtaSection must not overflow at 320 px',
          );
        },
      );
    });

    // -----------------------------------------------------------------------
    // RED: interaction tests — _onMerge is a no-op stub so contacts never
    // appear after a tap. These tests assert the INTENDED post-tap behavior
    // and will fail until the green pass implements _onMerge.
    // -----------------------------------------------------------------------
    group('tap interaction', () {
      testWidgets(
        '[RED] lite tap → instant merged + contacts panel visible',
        (tester) async {
          await _pumpSection(
            tester,
            effectsStore: const _FakeEffectsStore(stored: EffectsMode.lite),
          );
          await tester.pump();

          // Tap the merge button.
          await tester.tap(find.byType(MergeButton));
          // Single pump — lite mode is instant, no controller to wait on.
          await tester.pump();

          final l10n = AppLocalizations.of(
            tester.element(find.byType(MergeCtaSection)),
          );

          // Contacts heading must be visible.
          expect(
            find.text(l10n.cta_heading),
            findsOneWidget,
            reason: 'lite: after tap, cta_heading ("Get in touch") must appear',
          );

          // At least one contact label must render.
          expect(
            find.text('GitHub'),
            findsOneWidget,
            reason: 'lite: ContactsPanel with GitHub tile must be visible',
          );

          // Button label must switch to merged.
          expect(
            find.text('✓ merged'),
            findsOneWidget,
            reason: 'lite: button must show "✓ merged" label after tap',
          );

          // Lite took the no-controller path: contacts render as a plain
          // ContactsPanel, NOT wrapped in a FadeTransition (only the full-mode
          // animated path adds one). transientCallbackCount is unusable here —
          // the tapped button's Material ink splash registers one of its own.
          expect(
            find.descendant(
              of: find.byType(MergeCtaSection),
              matching: find.byType(FadeTransition),
            ),
            findsNothing,
            reason: 'lite: no FadeTransition — merged without a controller',
          );
        },
      );

      testWidgets(
        '[RED] full tap → merging label shown, FadeTransition present; '
        'pump 300 ms → merged label, contacts visible',
        (tester) async {
          await _pumpSection(
            tester,
            effectsStore: const _FakeEffectsStore(stored: EffectsMode.full),
          );
          // Single pump — do NOT pumpAndSettle; controller is lazy.
          await tester.pump();

          await tester.tap(find.byType(MergeButton));
          // One frame after tap: controller started, merging state shows.
          await tester.pump();

          expect(
            find.text('merging…'),
            findsOneWidget,
            reason:
                'full: immediately after tap the button must show "merging…"',
          );
          // FadeTransition wraps ContactsPanel in full mode while playing.
          // Scope to the CTA subtree — MaterialApp's route transition uses
          // FadeTransitions of its own.
          expect(
            find.descendant(
              of: find.byType(MergeCtaSection),
              matching: find.byType(FadeTransition),
            ),
            findsOneWidget,
            reason:
                'full: a FadeTransition must wrap ContactsPanel during merging',
          );

          // Drive the one-shot merge controller to completion (and let the
          // completed-status setState rebuild) deterministically.
          await tester.pumpAndSettle();

          expect(
            find.text('✓ merged'),
            findsOneWidget,
            reason: 'full: after animation, button must show "✓ merged"',
          );

          final l10n = AppLocalizations.of(
            tester.element(find.byType(MergeCtaSection)),
          );
          expect(
            find.text(l10n.cta_heading),
            findsOneWidget,
            reason: 'full: contacts heading must be visible after merge',
          );
        },
      );

      testWidgets(
        '[RED] idempotent — tapping again after merged does not break state',
        (tester) async {
          await _pumpSection(
            tester,
            effectsStore: const _FakeEffectsStore(stored: EffectsMode.full),
          );
          await tester.pump();

          // First tap → merged; settle the one-shot controller to completion.
          await tester.tap(find.byType(MergeButton));
          await tester.pumpAndSettle();

          // Verify merged.
          expect(find.text('✓ merged'), findsOneWidget);

          // Second tap — button is disabled (onPressed: null) when merged;
          // no exception, no duplicate contacts.
          await tester.tap(
            find.byType(MergeButton),
            warnIfMissed: false,
          );
          await tester.pump();

          expect(
            tester.takeException(),
            isNull,
            reason: 'tapping merged button must not throw',
          );
          expect(
            find.text('✓ merged'),
            findsOneWidget,
            reason: 'button must stay merged after second tap',
          );
          expect(
            find.byType(ContactsPanel),
            findsOneWidget,
            reason: 'exactly one ContactsPanel must be present (no duplicate)',
          );
        },
      );
    });

    // -----------------------------------------------------------------------
    // RED: i18n — heading only shows when merged, so these fail while stub.
    // -----------------------------------------------------------------------
    group('i18n heading after tap', () {
      testWidgets(
        '[RED] locale=ru, lite tap → "Свяжитесь" heading visible',
        (tester) async {
          await _pumpSection(
            tester,
            effectsStore: const _FakeEffectsStore(stored: EffectsMode.lite),
            locale: const Locale('ru'),
          );
          await tester.pump();

          await tester.tap(find.byType(MergeButton));
          await tester.pump();

          expect(
            find.text('Свяжитесь'),
            findsOneWidget,
            reason: 'locale=ru: cta_heading must render as "Свяжитесь"',
          );
        },
      );

      testWidgets(
        '[RED] locale=es, lite tap → "Hablemos" heading visible',
        (tester) async {
          await _pumpSection(
            tester,
            effectsStore: const _FakeEffectsStore(stored: EffectsMode.lite),
            locale: const Locale('es'),
          );
          await tester.pump();

          await tester.tap(find.byType(MergeButton));
          await tester.pump();

          expect(
            find.text('Hablemos'),
            findsOneWidget,
            reason:
                'locale=es: cta_heading must render as "Hablemos" after tap',
          );
        },
      );
    });
  });
}
