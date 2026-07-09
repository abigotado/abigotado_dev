import 'package:abigotado_dev/src/app/theme/app_theme.dart';
import 'package:abigotado_dev/src/app/view/editor_scroll_host.dart';
import 'package:abigotado_dev/src/app/view/editor_shell.dart';
import 'package:abigotado_dev/src/app/view/editor_sidebar.dart';
import 'package:abigotado_dev/src/app/view/editor_status_bar.dart';
import 'package:abigotado_dev/src/app/view/pane_content.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/core/effects/effects_store.dart';
import 'package:abigotado_dev/src/core/locale/locale_store.dart';
import 'package:abigotado_dev/src/core/locale/platform_locale_reader.dart';
import 'package:abigotado_dev/src/core/locale/supported_locale.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/features/hero/state/build_scenario_notifier.dart';
import 'package:abigotado_dev/src/features/hero/state/build_scenario_state.dart';
import 'package:abigotado_dev/src/features/hero/widget/debug_release_banner.dart';
import 'package:abigotado_dev/src/features/hotreload/widget/hot_reload_fab.dart';
import 'package:abigotado_dev/src/features/locale/state/locale_notifier.dart';
import 'package:abigotado_dev/src/features/readme/state/presentation_notifier.dart';
import 'package:abigotado_dev/src/features/readme/state/presentation_state.dart';
import 'package:abigotado_dev/src/features/readme/state/presentation_view.dart';
import 'package:abigotado_dev/src/features/readme/view/readme_view.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes — mirrors editor_shell_test.dart's override set.
// ---------------------------------------------------------------------------

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

final class _FixedBuildScenarioNotifier extends BuildScenarioNotifier {
  @override
  BuildScenarioState build() => const BuildScenarioState.released();
}

/// Fixes [PresentationNotifier] to a constant [PresentationState] — mirrors
/// editor_shell_test.dart's `_FixedScenarioNotifier` precedent.
final class _FixedPresentationNotifier extends PresentationNotifier {
  _FixedPresentationNotifier(this._initial);

  final PresentationState _initial;

  @override
  PresentationState build() => _initial;
}

// ---------------------------------------------------------------------------
// Helper: pump EditorShell(child: PaneContent()) with the presentation fixed
// to [view], at desktop width so the sidebar and chrome are all present.
// ---------------------------------------------------------------------------

Future<void> _pumpShell(
  WidgetTester tester, {
  required PresentationView view,
  Size surfaceSize = const Size(1280, 800),
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
        buildScenarioProvider.overrideWith(_FixedBuildScenarioNotifier.new),
        presentationProvider.overrideWith(
          () => _FixedPresentationNotifier(PresentationState(view: view)),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const EditorShell(child: PaneContent()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('PaneContent', () {
    // -------------------------------------------------------------------------
    // Structural swap — mostly born-green: PaneContent.build is already a
    // real `switch (ref.watch(readmeOpenProvider))`, not a stub. Passes on
    // stub — must STAY green.
    // -------------------------------------------------------------------------
    group('presentation switch', () {
      testWidgets(
        'pitch → EditorScrollHost present, ReadmeView absent',
        (tester) async {
          await _pumpShell(tester, view: PresentationView.pitch);

          expect(find.byType(EditorScrollHost), findsOneWidget);
          expect(find.byType(ReadmeView), findsNothing);
        },
      );

      testWidgets(
        'readme → ReadmeView present, EditorScrollHost absent',
        (tester) async {
          await _pumpShell(tester, view: PresentationView.readme);

          expect(find.byType(ReadmeView), findsOneWidget);
          expect(find.byType(EditorScrollHost), findsNothing);
        },
      );
    });

    // -------------------------------------------------------------------------
    group('chrome intact in both presentations', () {
      for (final view in PresentationView.values) {
        testWidgets(
          '${view.name}: sidebar, status bar, DebugReleaseBanner all present '
          'at 1280 wide',
          (tester) async {
            await _pumpShell(tester, view: view);

            expect(find.byType(EditorSidebar), findsOneWidget);
            expect(find.byType(EditorStatusBar), findsOneWidget);
            expect(find.byType(DebugReleaseBanner), findsOneWidget);
          },
        );
      }
    });

    // -------------------------------------------------------------------------
    // FAB visibility — RED: _PaneWithFab's `if (!readmeOpen)` guard reads the
    // REAL readmeOpenProvider, which derives from presentationProvider via a
    // `.select` — this is already real production code (not stubbed), so it
    // is falsifiable by the fixed-state override.
    // -------------------------------------------------------------------------
    group('FAB visibility', () {
      testWidgets('readme → HotReloadFab absent', (tester) async {
        await _pumpShell(tester, view: PresentationView.readme);

        expect(find.byType(HotReloadFab), findsNothing);
      });

      testWidgets('pitch → HotReloadFab present', (tester) async {
        await _pumpShell(tester, view: PresentationView.pitch);

        expect(find.byType(HotReloadFab), findsOneWidget);
      });
    });
  });
}
