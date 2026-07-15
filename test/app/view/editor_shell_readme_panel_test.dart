import 'package:abigotado_dev/src/app/theme/app_sizing.dart';
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
import 'package:abigotado_dev/src/features/locale/state/locale_notifier.dart';
import 'package:abigotado_dev/src/features/metrics/widget/metrics_section.dart';
import 'package:abigotado_dev/src/features/readme/state/presentation_notifier.dart';
import 'package:abigotado_dev/src/features/readme/state/presentation_state.dart';
import 'package:abigotado_dev/src/features/readme/state/presentation_view.dart';
import 'package:abigotado_dev/src/features/readme/view/readme_view.dart';
import 'package:abigotado_dev/src/features/readme/widget/readme_preview_panel.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Mixed red / born-green guards. `EditorShell`'s conditional third Row child
// is already real, implemented production code (contracts commit) — the
// PANEL it mounts, `ReadmePreviewPanel`, is still the shrink stub. So:
//   - breakpoint mount/unmount and the "cards keep 1000" invariant are
//     BORN-GREEN (the Row child and the layout chain around it are real);
//   - anything that depends on the panel actually RENDERING (its label, its
//     380 px width, the CTA) is RED.
// The AppSizing.readmePanelBreakpoint numeric invariant lives in
// test/app/theme/app_sizing_test.dart, not here.
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Fakes — the editor_shell_test.dart override set.
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

/// Fixes the build scenario to a released snapshot — same precedent as
/// editor_shell_test.dart's `_FixedScenarioNotifier`.
final class _FixedScenarioNotifier extends BuildScenarioNotifier {
  @override
  BuildScenarioState build() => const BuildScenarioState.released();
}

/// Fixes [PresentationNotifier] to a constant [PresentationState] — mirrors
/// pane_content_test.dart's `_FixedPresentationNotifier` precedent.
final class _FixedPresentationNotifier extends PresentationNotifier {
  _FixedPresentationNotifier(this._initial);

  final PresentationState _initial;

  @override
  PresentationState build() => _initial;
}

// ---------------------------------------------------------------------------
// Helper: pump EditorShell(child: child) at a fixed surface size, with the
// editor_shell_test.dart override set. [fixedView] is null by default (real
// presentationProvider, defaulting to pitch); pass it to pin the panel's
// `readmeOpenProvider` guard for the dead-strip test.
// ---------------------------------------------------------------------------

Future<void> _pumpShell(
  WidgetTester tester, {
  required Widget child,
  required Size surfaceSize,
  PresentationView? fixedView,
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
        buildScenarioProvider.overrideWith(_FixedScenarioNotifier.new),
        if (fixedView != null)
          presentationProvider.overrideWith(
            () =>
                _FixedPresentationNotifier(PresentationState(view: fixedView)),
          ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: EditorShell(child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('EditorShell', () {
    group('README preview panel — breakpoint visibility', () {
      testWidgets(
        '1600×900, pitch → ReadmePreviewPanel present, rm_panel_label '
        'present, chrome intact (EditorSidebar, EditorStatusBar, content)',
        (tester) async {
          await _pumpShell(
            tester,
            child: const Text('CONTENT-MARKER'),
            surfaceSize: const Size(1600, 900),
          );
          final l10n = AppLocalizations.of(
            tester.element(find.byType(EditorShell)),
          );

          expect(find.byType(ReadmePreviewPanel), findsOneWidget);
          expect(
            find.text(l10n.rm_panel_label),
            findsOneWidget,
            reason:
                'RED vs the shrink stub — the header strip has not landed '
                'yet',
          );
          expect(find.byType(EditorSidebar), findsOneWidget);
          expect(find.byType(EditorStatusBar), findsOneWidget);
          expect(find.text('CONTENT-MARKER'), findsOneWidget);
        },
      );

      testWidgets(
        '1440×900 → ReadmePreviewPanel absent (below the breakpoint)',
        (tester) async {
          await _pumpShell(
            tester,
            child: const Text('CONTENT-MARKER'),
            surfaceSize: const Size(1440, 900),
          );

          expect(find.byType(ReadmePreviewPanel), findsNothing);
        },
      );

      testWidgets(
        '1280×900 → ReadmePreviewPanel absent (below the breakpoint)',
        (tester) async {
          await _pumpShell(
            tester,
            child: const Text('CONTENT-MARKER'),
            surfaceSize: const Size(1280, 900),
          );

          expect(find.byType(ReadmePreviewPanel), findsNothing);
        },
      );
    });

    // -------------------------------------------------------------------------
    // Guard: EditorShell mounts ReadmePreviewPanel purely on viewport width —
    // it does NOT gate on readmeOpenProvider (see EditorShell class doc: the
    // panel decides for itself, once mounted, whether to render). So this
    // must never regress into a visible-but-dead 380 px strip once the panel
    // is open: the panel's OWN internal guard must still fully collapse it.
    // -------------------------------------------------------------------------
    group('README preview panel — hidden while the README is open', () {
      testWidgets(
        '1600×900, presentation fixed to readme → ReadmePreviewPanel still '
        'mounts (width-only gate) but rm_panel_label absent and panel width '
        '0 (no dead strip)',
        (tester) async {
          await _pumpShell(
            tester,
            child: const Text('CONTENT-MARKER'),
            surfaceSize: const Size(1600, 900),
            fixedView: PresentationView.readme,
          );
          final l10n = AppLocalizations.of(
            tester.element(find.byType(EditorShell)),
          );

          expect(find.byType(ReadmePreviewPanel), findsOneWidget);
          expect(find.text(l10n.rm_panel_label), findsNothing);
          expect(
            tester.getSize(find.byType(ReadmePreviewPanel)).width,
            equals(0),
          );
        },
      );
    });

    // -------------------------------------------------------------------------
    // Advisor hardening #1: the panel must never squeeze the pitch's content
    // column below its normal AppSizing.contentMaxWidth measure. Holds
    // trivially now (stub panel is 0 px wide) and must STAY green once the
    // real 380 px panel lands — AppSizing.readmePanelBreakpoint (1600) was
    // chosen with 24 px of headroom above the exact squeeze floor precisely
    // so this holds (see AppSizing.readmePanelBreakpoint doc and
    // test/app/theme/app_sizing_test.dart).
    // -------------------------------------------------------------------------
    group('content column keeps its cap at the breakpoint', () {
      const expectedWrapWidth =
          AppSizing.contentMaxWidth - 2 * AppSizing.contentGutter;

      testWidgets(
        '1280×900, pitch, PaneContent → metrics Wrap width equals '
        'contentMaxWidth − 2×contentGutter ($expectedWrapWidth)',
        (tester) async {
          await _pumpShell(
            tester,
            child: const PaneContent(),
            surfaceSize: const Size(1280, 900),
          );

          final wrapFinder = find.descendant(
            of: find.byType(MetricsSection),
            matching: find.byType(Wrap),
          );
          expect(
            tester.getSize(wrapFinder).width,
            equals(expectedWrapWidth),
          );
        },
      );

      testWidgets(
        '1600×900, pitch, PaneContent → metrics Wrap width equals '
        'contentMaxWidth − 2×contentGutter ($expectedWrapWidth) — unchanged '
        'from 1280, the panel must not squeeze it',
        (tester) async {
          await _pumpShell(
            tester,
            child: const PaneContent(),
            surfaceSize: const Size(1600, 900),
          );

          final wrapFinder = find.descendant(
            of: find.byType(MetricsSection),
            matching: find.byType(Wrap),
          );
          expect(
            tester.getSize(wrapFinder).width,
            equals(expectedWrapWidth),
          );
        },
      );
    });

    group('CTA integration', () {
      testWidgets(
        '1600×900, PaneContent, tap rm_panel_open → ReadmeView present, '
        'EditorScrollHost gone, Navigator.canPop true',
        (tester) async {
          await _pumpShell(
            tester,
            child: const PaneContent(),
            surfaceSize: const Size(1600, 900),
          );
          final l10n = AppLocalizations.of(
            tester.element(find.byType(EditorShell)),
          );

          final ctaFinder = find.widgetWithText(InkWell, l10n.rm_panel_open);
          expect(ctaFinder, findsOneWidget);

          await tester.tap(ctaFinder);
          await tester.pumpAndSettle();

          expect(find.byType(ReadmeView), findsOneWidget);
          expect(find.byType(EditorScrollHost), findsNothing);
          expect(
            Navigator.of(tester.element(find.byType(ReadmeView))).canPop(),
            isTrue,
            reason:
                'the panel CTA must arm the same A3 LocalHistoryEntry '
                'contract as every other README trigger',
          );
        },
      );
    });

    group('animation', () {
      testWidgets(
        '1600×900 lite, PaneContent → transientCallbackCount == 0',
        (tester) async {
          await _pumpShell(
            tester,
            child: const PaneContent(),
            surfaceSize: const Size(1600, 900),
          );

          expect(tester.binding.transientCallbackCount, equals(0));
        },
      );
    });
  });
}
