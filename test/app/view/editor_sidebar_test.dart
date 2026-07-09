import 'package:abigotado_dev/src/app/state/scroll_spy_notifier.dart';
import 'package:abigotado_dev/src/app/theme/app_theme.dart';
import 'package:abigotado_dev/src/app/view/editor_sidebar.dart';
import 'package:abigotado_dev/src/app/widget/editor_file.dart';
import 'package:abigotado_dev/src/app/widget/editor_file_row.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/core/effects/effects_store.dart';
import 'package:abigotado_dev/src/core/locale/locale_store.dart';
import 'package:abigotado_dev/src/core/locale/platform_locale_reader.dart';
import 'package:abigotado_dev/src/core/locale/supported_locale.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/features/locale/state/locale_notifier.dart';
import 'package:abigotado_dev/src/features/readme/state/presentation_notifier.dart';
import 'package:abigotado_dev/src/features/readme/state/presentation_state.dart';
import 'package:abigotado_dev/src/features/readme/state/presentation_view.dart';
import 'package:abigotado_dev/src/features/readme/view/readme_navigation.dart';
import 'package:abigotado_dev/src/features/readme/widget/readme_sidebar_row.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes — mirrors editor_shell_test.dart
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

/// Fixes [PresentationNotifier] to a constant [PresentationState] — mirrors
/// editor_shell_test.dart's `_FixedScenarioNotifier` precedent.
final class _FixedPresentationNotifier extends PresentationNotifier {
  _FixedPresentationNotifier(this._initial);

  final PresentationState _initial;

  @override
  PresentationState build() => _initial;
}

// ---------------------------------------------------------------------------
// Probe: exposes a real WidgetRef to the test — mirrors
// effects_toggle_test.dart's `_EffectsModeHarness` — so a test can call the
// real `openReadme` navigation helper and arm a genuine LocalHistoryEntry.
// ---------------------------------------------------------------------------

class _RefProbe extends ConsumerWidget {
  const _RefProbe({required this.notifier});

  final ValueNotifier<WidgetRef?> notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    notifier.value = ref;
    return const SizedBox.shrink();
  }
}

// ---------------------------------------------------------------------------
// Helper: pump EditorSidebar inside a pre-built container + Material tree.
// ---------------------------------------------------------------------------

Future<void> _pumpSidebar(
  WidgetTester tester,
  ProviderContainer container, {
  ValueNotifier<WidgetRef?>? refNotifier,
}) async {
  await tester.binding.setSurfaceSize(const Size(200, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Column(
            children: [
              const Expanded(child: EditorSidebar()),
              if (refNotifier != null) _RefProbe(notifier: refNotifier),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('EditorSidebar', () {
    // -------------------------------------------------------------------------
    // Structural guard: the contract already passes `selected: f == active` to
    // each EditorFileRow, so this test verifies the prop wiring is correct.
    // It will be green now. Keep it as a regression guard: if the prop wiring
    // ever breaks a real bug will surface here.
    testWidgets(
      'highlights exactly the active file row',
      (tester) async {
        // Override the derived provider directly so we don't drive the stubbed
        // notifier — the derived provider is already real.
        final container = ProviderContainer(
          overrides: [
            localeStoreProvider.overrideWithValue(const _FakeLocaleStore()),
            platformReaderProvider.overrideWithValue(
              const _FakePlatformLocaleReader(),
            ),
            effectsStoreProvider.overrideWithValue(
              const _FakeEffectsStore(),
            ),
            activeEditorFileValueProvider.overrideWithValue(
              EditorFile.pubspec,
            ),
          ],
        );
        addTearDown(container.dispose);
        await _pumpSidebar(tester, container);

        final rows = tester
            .widgetList<EditorFileRow>(find.byType(EditorFileRow))
            .toList();

        // Exactly one row must be selected.
        final selectedRows = rows.where((r) => r.selected).toList();
        expect(selectedRows.length, equals(1));

        // The selected row is pubspec.
        expect(selectedRows.first.file, equals(EditorFile.pubspec));

        // All other rows are not selected.
        final unselectedRows = rows.where((r) => !r.selected).toList();
        for (final row in unselectedRows) {
          expect(row.file, isNot(equals(EditorFile.pubspec)));
        }
      },
    );

    // -------------------------------------------------------------------------
    // RED: tapping a row dispatches requestScrollTo for that file.
    // Row has no InkWell yet → tap fires nothing → scrollRequest stays null.
    testWidgets(
      'tapping a row dispatches requestScrollTo for that file',
      (tester) async {
        // Do NOT override the notifier: we want to test the real
        // requestScrollTo dispatch path end-to-end.
        final container = ProviderContainer(
          overrides: [
            localeStoreProvider.overrideWithValue(const _FakeLocaleStore()),
            platformReaderProvider.overrideWithValue(
              const _FakePlatformLocaleReader(),
            ),
            effectsStoreProvider.overrideWithValue(
              const _FakeEffectsStore(),
            ),
          ],
        );
        addTearDown(container.dispose);
        await _pumpSidebar(tester, container);

        // Tap the pubspec.yaml row by its filename text.
        await tester.tap(find.text('pubspec.yaml'));
        await tester.pump();

        // After the tap, the notifier must have a pending scroll request.
        // Fails until: EditorFileRow wraps in InkWell AND requestScrollTo is
        // implemented (both green-pass items).
        expect(
          container.read(scrollSpyProvider).scrollRequest?.target,
          equals(EditorFile.pubspec),
        );
      },
    );

    // -------------------------------------------------------------------------
    // README row — stub: ReadmeSidebarRow.build returns SizedBox.shrink, so
    // neither the invariant filename nor the decoded label render yet.
    // -------------------------------------------------------------------------
    group('README row', () {
      testWidgets(
        "renders 'README.md' and the l10n.file_readme decode label",
        (tester) async {
          final container = ProviderContainer(
            overrides: [
              localeStoreProvider.overrideWithValue(const _FakeLocaleStore()),
              platformReaderProvider.overrideWithValue(
                const _FakePlatformLocaleReader(),
              ),
              effectsStoreProvider.overrideWithValue(
                const _FakeEffectsStore(),
              ),
            ],
          );
          addTearDown(container.dispose);
          await _pumpSidebar(tester, container);
          final l10n = AppLocalizations.of(
            tester.element(find.byType(EditorSidebar)),
          );

          expect(find.text('README.md'), findsOneWidget);
          expect(find.text(l10n.file_readme), findsOneWidget);
        },
      );
    });

    // -------------------------------------------------------------------------
    // README-open exclusivity — RED: ReadmeSidebarRow.build is a stub, so it
    // never exposes Semantics(selected: true) regardless of readmeOpenProvider.
    // -------------------------------------------------------------------------
    group('README open — selection exclusivity', () {
      testWidgets(
        'ReadmeSidebarRow selected AND zero EditorFileRows selected',
        (tester) async {
          final container = ProviderContainer(
            overrides: [
              localeStoreProvider.overrideWithValue(const _FakeLocaleStore()),
              platformReaderProvider.overrideWithValue(
                const _FakePlatformLocaleReader(),
              ),
              effectsStoreProvider.overrideWithValue(
                const _FakeEffectsStore(),
              ),
              activeEditorFileValueProvider.overrideWithValue(
                EditorFile.pubspec,
              ),
              presentationProvider.overrideWith(
                () => _FixedPresentationNotifier(
                  const PresentationState(view: PresentationView.readme),
                ),
              ),
            ],
          );
          addTearDown(container.dispose);
          final handle = tester.ensureSemantics();
          await _pumpSidebar(tester, container);

          // isSemantics (subset match) — raw SemanticsData flags are a
          // Tristate enum on Flutter 3.44, so comparing them to a bool can
          // never pass; see editor_file_row_test for the same pattern.
          expect(
            tester.getSemantics(find.byType(ReadmeSidebarRow)),
            isSemantics(isSelected: true),
            reason: 'ReadmeSidebarRow must be selected while readme is open',
          );

          final selectedFileRows = tester
              .widgetList<EditorFileRow>(find.byType(EditorFileRow))
              .where((r) => r.selected)
              .toList();
          expect(
            selectedFileRows,
            isEmpty,
            reason:
                'no EditorFileRow may be selected while the README is open '
                '— selection is exclusive to ReadmeSidebarRow',
          );

          handle.dispose();
        },
      );
    });

    // -------------------------------------------------------------------------
    // Tapping a pitch row while the README is open must close it — RED: the
    // sidebar's onTap already calls Navigator.of(context).maybePop(), but
    // that only resolves true once openReadme has armed a real
    // LocalHistoryEntry (currently throws UnimplementedError), so readmeOpen
    // never flips and the assertions below fail on the stub.
    // -------------------------------------------------------------------------
    group('tap a pitch row while README open', () {
      testWidgets(
        'closes the README (readmeOpen flips false) AND requests a scroll '
        'to the tapped file',
        (tester) async {
          final container = ProviderContainer(
            overrides: [
              localeStoreProvider.overrideWithValue(const _FakeLocaleStore()),
              platformReaderProvider.overrideWithValue(
                const _FakePlatformLocaleReader(),
              ),
              effectsStoreProvider.overrideWithValue(
                const _FakeEffectsStore(),
              ),
            ],
          );
          addTearDown(container.dispose);
          final refNotifier = ValueNotifier<WidgetRef?>(null);
          addTearDown(refNotifier.dispose);
          await _pumpSidebar(tester, container, refNotifier: refNotifier);

          // Arm a REAL LocalHistoryEntry via the real openReadme helper (not
          // a fixed-state override) — the sidebar's onTap pops it via
          // Navigator.maybePop, so the precondition must be the genuine
          // navigation path this test exercises.
          final probeContext = tester.element(find.byType(_RefProbe));
          final ref = refNotifier.value;
          expect(ref, isNotNull, reason: 'the probe must have captured a ref');
          openReadme(probeContext, ref!);
          await tester.pumpAndSettle();
          expect(
            container.read(readmeOpenProvider),
            isTrue,
            reason: 'precondition: the README must be open before the tap',
          );

          await tester.tap(find.text('pubspec.yaml'));
          await tester.pump();
          await tester.pumpAndSettle();

          expect(
            container.read(readmeOpenProvider),
            isFalse,
            reason: 'tapping a pitch row while README is open must close it',
          );
          expect(
            container.read(scrollSpyProvider).scrollRequest?.target,
            equals(EditorFile.pubspec),
            reason:
                'the tapped file must still be requested as the return-to '
                '-pitch scroll target',
          );
        },
      );
    });
  });
}
