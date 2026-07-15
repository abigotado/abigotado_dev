import 'package:abigotado_dev/src/app/theme/app_sizing.dart';
import 'package:abigotado_dev/src/app/theme/app_theme.dart';
import 'package:abigotado_dev/src/app/widget/contact_link_tile.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/core/effects/effects_store.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/features/readme/content/experience_content.dart';
import 'package:abigotado_dev/src/features/readme/state/presentation_notifier.dart';
import 'package:abigotado_dev/src/features/readme/state/presentation_state.dart';
import 'package:abigotado_dev/src/features/readme/state/presentation_view.dart';
import 'package:abigotado_dev/src/features/readme/widget/readme_preview_panel.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// RED vs the shrink stub. `ReadmePreviewPanel.build` returns
// `SizedBox.shrink()` unconditionally as of the stage-2 contracts commit —
// every behavioral assertion below (header strip, headerCrop content, CTA,
// real width) is expected to FAIL until the green pass implements the tree
// sketched in the widget's class doc. The "static" test is the one
// born-green guard in this file (nothing here has any animation, stub or
// not).
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Fakes
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

/// Fixes [PresentationNotifier] to a constant [PresentationState] — mirrors
/// pane_content_test.dart's `_FixedPresentationNotifier` precedent.
final class _FixedPresentationNotifier extends PresentationNotifier {
  _FixedPresentationNotifier(this._initial);

  final PresentationState _initial;

  @override
  PresentationState build() => _initial;
}

// ---------------------------------------------------------------------------
// Helper: pump ReadmePreviewPanel as the trailing child of a Row, the other
// child an Expanded placeholder standing in for the editor content pane —
// mirrors EditorShell's real desktop Row (sidebar / Expanded content /
// ReadmePreviewPanel). MaterialApp(home: Scaffold(...)) gives the panel a
// root ModalRoute, exactly like every other openReadme call site.
//
// [fixedView] is null by default — most tests exercise the REAL
// presentationProvider (so the CTA test drives the actual openReadme funnel,
// not a fake). Only the "hidden when open" test fixes it.
// ---------------------------------------------------------------------------

Future<ProviderContainer> _pumpPanel(
  WidgetTester tester, {
  Size surface = const Size(1200, 900),
  Locale locale = const Locale('en'),
  PresentationView? fixedView,
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final container = ProviderContainer(
    overrides: [
      effectsStoreProvider.overrideWithValue(const _FakeEffectsStore()),
      if (fixedView != null)
        presentationProvider.overrideWith(
          () => _FixedPresentationNotifier(PresentationState(view: fixedView)),
        ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: Row(
            children: [
              Expanded(child: SizedBox()),
              ReadmePreviewPanel(),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return container;
}

void main() {
  group('ReadmePreviewPanel', () {
    group('header strip', () {
      testWidgets(
        'renders rm_tab_title and rm_panel_label',
        (tester) async {
          await _pumpPanel(tester);
          final l10n = AppLocalizations.of(
            tester.element(find.byType(Scaffold)),
          );

          expect(find.text(l10n.rm_tab_title), findsOneWidget);
          expect(find.text(l10n.rm_panel_label), findsOneWidget);
        },
      );
    });

    group('headerCrop content', () {
      testWidgets(
        'renders name/rm_role/rm_collab_intro/rm_about but no experience '
        'org string and no ContactLinkTile',
        (tester) async {
          await _pumpPanel(tester);
          final l10n = AppLocalizations.of(
            tester.element(find.byType(Scaffold)),
          );

          expect(find.text(l10n.name), findsOneWidget);
          expect(find.text(l10n.rm_role), findsOneWidget);
          expect(find.text(l10n.rm_collab_intro), findsOneWidget);
          expect(find.text(l10n.rm_about), findsOneWidget);

          for (final entry in experienceEntries) {
            expect(
              find.text(entry.org(l10n)),
              findsNothing,
              reason:
                  'the panel shows the headerCrop only — org '
                  '"${entry.org(l10n)}" must be absent',
            );
          }
          expect(find.byType(ContactLinkTile), findsNothing);
        },
      );
    });

    group('CTA', () {
      testWidgets(
        'rm_panel_open renders at ≥44 px and tapping it funnels through '
        'openReadme — readmeOpenProvider true, Navigator.canPop true',
        (tester) async {
          final container = await _pumpPanel(tester);
          final l10n = AppLocalizations.of(
            tester.element(find.byType(Scaffold)),
          );

          final ctaFinder = find.widgetWithText(InkWell, l10n.rm_panel_open);
          expect(ctaFinder, findsOneWidget);
          expect(
            tester.getSize(ctaFinder).height,
            greaterThanOrEqualTo(44),
            reason: 'CTA tap target must clear WCAG 2.5.5 (≥44 px)',
          );

          await tester.tap(ctaFinder);
          await tester.pumpAndSettle();

          expect(container.read(readmeOpenProvider), isTrue);
          expect(
            Navigator.of(
              tester.element(find.byType(ReadmePreviewPanel)),
            ).canPop(),
            isTrue,
            reason:
                'the CTA must funnel through openReadme, which arms the '
                'LocalHistoryEntry — the same A3 browser-Back contract every '
                'other README trigger uses',
          );
        },
      );
    });

    group('hidden when the README is open', () {
      testWidgets(
        'presentation fixed to readme → rm_panel_label absent and the '
        'panel contributes zero width',
        (tester) async {
          await _pumpPanel(tester, fixedView: PresentationView.readme);
          final l10n = AppLocalizations.of(
            tester.element(find.byType(Scaffold)),
          );

          expect(find.text(l10n.rm_panel_label), findsNothing);
          expect(
            tester.getSize(find.byType(ReadmePreviewPanel)).width,
            equals(0),
            reason:
                'the panel owns its own width — hiding it must reclaim the '
                '380 px for the content pane, not leave a blank strip',
          );
        },
      );
    });

    group('width when visible', () {
      testWidgets(
        'pitch presentation → panel width equals AppSizing.readmePanelWidth',
        (tester) async {
          await _pumpPanel(tester, fixedView: PresentationView.pitch);

          expect(
            tester.getSize(find.byType(ReadmePreviewPanel)).width,
            equals(AppSizing.readmePanelWidth),
          );
        },
      );
    });

    group('animation', () {
      testWidgets(
        'panel subtree declares no implicit animations and no transient '
        'callbacks are registered',
        (tester) async {
          await _pumpPanel(tester);

          // Structural, not just timing: a finite AnimatedContainer would
          // have drained before pumpAndSettle returned and a bare
          // transientCallbackCount check would stay green — the widget
          // predicate catches the declaration itself.
          expect(
            find.descendant(
              of: find.byType(ReadmePreviewPanel),
              matching: find.byWidgetPredicate(
                (w) => w is ImplicitlyAnimatedWidget,
              ),
            ),
            findsNothing,
            reason:
                'ReadmePreviewPanel is static by contract — no AnimatedX '
                'widgets in stage 2',
          );
          expect(tester.binding.transientCallbackCount, equals(0));
        },
      );
    });
  });
}
