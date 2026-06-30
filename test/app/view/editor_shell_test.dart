import 'package:abigotado_dev/src/app/theme/app_theme.dart';
import 'package:abigotado_dev/src/app/view/editor_pane.dart';
import 'package:abigotado_dev/src/app/view/editor_shell.dart';
import 'package:abigotado_dev/src/app/view/editor_sidebar.dart';
import 'package:abigotado_dev/src/app/view/editor_status_bar.dart';
import 'package:abigotado_dev/src/app/widget/background/living_background.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/core/effects/effects_store.dart';
import 'package:abigotado_dev/src/core/locale/locale_store.dart';
import 'package:abigotado_dev/src/core/locale/platform_locale_reader.dart';
import 'package:abigotado_dev/src/core/locale/supported_locale.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/features/effects/widget/effects_toggle.dart';
import 'package:abigotado_dev/src/features/hero/state/build_scenario_notifier.dart';
import 'package:abigotado_dev/src/features/hero/state/build_scenario_state.dart';
import 'package:abigotado_dev/src/features/hero/widget/debug_release_banner.dart';
import 'package:abigotado_dev/src/features/locale/state/locale_notifier.dart';
import 'package:abigotado_dev/src/features/locale/widget/locale_switcher.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

// Fixes effects to EffectsMode.lite so no animation controllers run and
// pumpAndSettle does not time out.
final class _FakeEffectsStore implements EffectsStore {
  const _FakeEffectsStore();

  @override
  EffectsMode? read() => EffectsMode.lite;

  @override
  Future<void> write(EffectsMode mode) async {}

  @override
  Future<void> clear() async {}
}

final class _FakeLocaleStore implements LocaleStore {
  const _FakeLocaleStore();

  @override
  SupportedLocale? read() => null;

  @override
  Future<void> write(SupportedLocale locale) async {}

  @override
  Future<void> clear() async {}
}

final class _FakePlatformLocaleReader implements PlatformLocaleReader {
  const _FakePlatformLocaleReader();

  @override
  List<Locale> get locales => const [];

  @override
  String? get timeZoneId => null;
}

// Fixes the build scenario to a released snapshot so the phase-driven
// ReleaseTag shows RELEASE without needing a live TerminalHero.
// Local to this file; do NOT extract to a shared support file.
final class _FixedScenarioNotifier extends BuildScenarioNotifier {
  _FixedScenarioNotifier(this._initial);

  final BuildScenarioState _initial;

  @override
  BuildScenarioState build() => _initial;
}

// ---------------------------------------------------------------------------
// Helper: pump EditorShell inside the full provider + Material tree.
// ---------------------------------------------------------------------------

Future<void> _pumpShell(
  WidgetTester tester, {
  required Size surfaceSize,
  Locale locale = const Locale('en'),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localeStoreProvider.overrideWithValue(const _FakeLocaleStore()),
        platformReaderProvider.overrideWithValue(
          const _FakePlatformLocaleReader(),
        ),
        effectsStoreProvider.overrideWithValue(const _FakeEffectsStore()),
        // Pin the scenario to released so the phase-driven ReleaseTag shows
        // RELEASE. The shell's child is Text('CONTENT-MARKER') — there is no
        // TerminalHero to advance the scenario from planning.
        buildScenarioProvider.overrideWith(
          () => _FixedScenarioNotifier(const BuildScenarioState.released()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const EditorShell(child: Text('CONTENT-MARKER')),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('EditorShell', () {
    group('sidebar visibility — responsive', () {
      testWidgets(
        'desktop (1280×800) shows EditorSidebar with EXPLORER header',
        (tester) async {
          await _pumpShell(tester, surfaceSize: const Size(1280, 800));

          expect(find.byType(EditorSidebar), findsOneWidget);
          expect(find.text('EXPLORER'), findsOneWidget);
        },
      );

      testWidgets(
        'mobile (360×800) hides EditorSidebar',
        (tester) async {
          await _pumpShell(tester, surfaceSize: const Size(360, 800));

          expect(find.byType(EditorSidebar), findsNothing);
        },
      );
    });

    group('sidebar visibility — breakpoint boundary', () {
      testWidgets(
        'width 899 → EditorSidebar absent',
        (tester) async {
          await _pumpShell(tester, surfaceSize: const Size(899, 800));

          expect(find.byType(EditorSidebar), findsNothing);
        },
      );

      testWidgets(
        'width 900 → EditorSidebar present',
        (tester) async {
          await _pumpShell(tester, surfaceSize: const Size(900, 800));

          expect(find.byType(EditorSidebar), findsOneWidget);
        },
      );
    });

    group('status bar', () {
      testWidgets(
        'EditorStatusBar present at desktop width (1280)',
        (tester) async {
          await _pumpShell(tester, surfaceSize: const Size(1280, 800));

          expect(find.byType(EditorStatusBar), findsOneWidget);
        },
      );

      testWidgets(
        'EditorStatusBar present at mobile width (360)',
        (tester) async {
          await _pumpShell(tester, surfaceSize: const Size(360, 800));

          expect(find.byType(EditorStatusBar), findsOneWidget);
        },
      );
    });

    group('status bar — no overflow at narrow phone widths (es locale)', () {
      // These tests guard the BLOCKER fix: the compact Wrap layout must never
      // overflow at 320 or 360 px even with the widest locale strings (Spanish
      // "Efectos activados" is the hardest case).
      testWidgets(
        'no RenderFlex overflow at 320×800 in es locale',
        (tester) async {
          await _pumpShell(
            tester,
            surfaceSize: const Size(320, 800),
            locale: const Locale('es'),
          );

          // tester.takeException() returns the first uncaught exception from
          // pumpAndSettle — a RenderFlex overflow would surface here.
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'no RenderFlex overflow at 360×800 in es locale',
        (tester) async {
          await _pumpShell(
            tester,
            surfaceSize: const Size(360, 800),
            locale: const Locale('es'),
          );

          expect(tester.takeException(), isNull);
        },
      );
    });

    group('status bar — switchers', () {
      testWidgets(
        'LocaleSwitcher is a descendant of EditorStatusBar at desktop width',
        (tester) async {
          await _pumpShell(tester, surfaceSize: const Size(1280, 800));

          expect(
            find.descendant(
              of: find.byType(EditorStatusBar),
              matching: find.byType(LocaleSwitcher),
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'EffectsToggle is a descendant of EditorStatusBar at desktop width',
        (tester) async {
          await _pumpShell(tester, surfaceSize: const Size(1280, 800));

          expect(
            find.descendant(
              of: find.byType(EditorStatusBar),
              matching: find.byType(EffectsToggle),
            ),
            findsOneWidget,
          );
        },
      );
    });

    group('release tag — released', () {
      testWidgets(
        'RELEASE text present and no DEBUG text',
        (tester) async {
          await _pumpShell(tester, surfaceSize: const Size(1280, 800));

          expect(find.text('RELEASE'), findsOneWidget);
          expect(find.textContaining('DEBUG'), findsNothing);
        },
      );

      testWidgets(
        'no transient callbacks after pumpAndSettle — no ticker running',
        (tester) async {
          await _pumpShell(tester, surfaceSize: const Size(1280, 800));

          expect(
            tester.binding.transientCallbackCount,
            equals(0),
            reason:
                'lite mode + static ReleaseTag must leave zero transient '
                'callbacks running',
          );
        },
      );
    });

    // -------------------------------------------------------------------------
    // FIX-1: the DEBUG/RELEASE ribbon wraps the WHOLE editor window (the corner
    // of the entire site), not the hero terminal panel. Asserted at the shell
    // level here — the banner must be an ancestor of BOTH the sidebar and the
    // content. The banner's per-phase label/colour is covered in isolation by
    // debug_release_banner_test; this group only pins its placement.
    // -------------------------------------------------------------------------

    group('release ribbon — whole-shell scope (FIX-1)', () {
      testWidgets(
        'DebugReleaseBanner wraps the whole shell: ancestor of both sidebar '
        'and content, reading RELEASE on the top-end corner',
        (tester) async {
          await _pumpShell(tester, surfaceSize: const Size(1280, 800));

          // The ribbon encloses the entire editor window: both the file-tree
          // sidebar and the editor content descend from the single banner.
          expect(
            find.ancestor(
              of: find.byType(EditorSidebar),
              matching: find.byType(DebugReleaseBanner),
            ),
            findsOneWidget,
            reason: 'ribbon must wrap the sidebar (whole-site corner, FIX-1)',
          );
          expect(
            find.ancestor(
              of: find.text('CONTENT-MARKER'),
              matching: find.byType(DebugReleaseBanner),
            ),
            findsOneWidget,
            reason: 'ribbon must wrap the editor content too',
          );

          // The diagonal corner Banner (distinct from the status-bar ReleaseTag
          // Text) reads RELEASE and sits on the top-end corner.
          final banners = tester.widgetList<Banner>(
            find.descendant(
              of: find.byType(DebugReleaseBanner),
              matching: find.byType(Banner),
            ),
          );
          expect(
            banners.any((b) => b.message == 'RELEASE'),
            isTrue,
            reason: 'shell ribbon must read RELEASE in the released scenario',
          );
          expect(
            banners.every((b) => b.location == BannerLocation.topEnd),
            isTrue,
            reason: 'ribbon sits on the top-end corner of the whole window',
          );
        },
      );

      testWidgets(
        'ribbon lives above the content pane, not inside it (regression guard)',
        (tester) async {
          await _pumpShell(tester, surfaceSize: const Size(1280, 800));

          // A Banner inside the EditorPane would mean the ribbon only covers
          // the content area — the exact bug FIX-1 corrects.
          expect(
            find.descendant(
              of: find.byType(EditorPane),
              matching: find.byType(Banner),
            ),
            findsNothing,
            reason: 'ribbon must wrap the whole window, not the content pane',
          );
        },
      );
    });

    // -------------------------------------------------------------------------
    // Backdrop framing regressions — GREEN guards (Stack already wired).
    // These assert that LivingBackground is present and shares a Stack with
    // the content layer, so a future refactor cannot accidentally remove it.
    // -------------------------------------------------------------------------

    group('backdrop framing', () {
      testWidgets(
        'LivingBackground present at desktop (1280)',
        (tester) async {
          await _pumpShell(tester, surfaceSize: const Size(1280, 800));

          expect(
            find.byType(LivingBackground),
            findsOneWidget,
            reason: 'LivingBackground must be mounted inside EditorShell',
          );
        },
      );

      testWidgets(
        'LivingBackground present at mobile (360)',
        (tester) async {
          await _pumpShell(tester, surfaceSize: const Size(360, 800));

          expect(
            find.byType(LivingBackground),
            findsOneWidget,
            reason: 'LivingBackground must be mounted at mobile width too',
          );
        },
      );

      testWidgets(
        'background and content share one Stack',
        (tester) async {
          await _pumpShell(tester, surfaceSize: const Size(1280, 800));

          // Both LivingBackground and EditorPane must descend from a common
          // Stack in the Scaffold body. Find the Stack ancestors of each and
          // confirm the first ancestor Stack is the same element.
          final backgroundStackFinder = find.ancestor(
            of: find.byType(LivingBackground),
            matching: find.byType(Stack),
          );
          final paneStackFinder = find.ancestor(
            of: find.byType(EditorPane),
            matching: find.byType(Stack),
          );

          expect(
            backgroundStackFinder,
            findsOneWidget,
            reason: 'LivingBackground must have exactly one Stack ancestor',
          );
          // EditorPane now also lives inside the FAB-over-pane Stack, so it
          // has two Stack ancestors; the backdrop Stack (the background's) must
          // still be one of them — content is framed over the single shared
          // living-background Stack.
          expect(
            paneStackFinder,
            findsNWidgets(2),
            reason:
                'EditorPane descends from the backdrop Stack and the inner '
                'FAB-over-pane Stack',
          );
          expect(
            tester.elementList(paneStackFinder),
            contains(tester.element(backgroundStackFinder)),
            reason:
                'LivingBackground and EditorPane must share the same backdrop '
                'Stack (content framed over the living background)',
          );
        },
      );

      testWidgets(
        'CONTENT-MARKER still renders above the backdrop',
        (tester) async {
          await _pumpShell(tester, surfaceSize: const Size(1280, 800));

          expect(
            find.text('CONTENT-MARKER'),
            findsOneWidget,
            reason:
                'The Scaffold child text must be visible above the backdrop',
          );
        },
      );
    });
  });
}
