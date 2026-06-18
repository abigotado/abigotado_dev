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

// ---------------------------------------------------------------------------
// Helper: pump EditorSidebar inside a pre-built container + Material tree.
// ---------------------------------------------------------------------------

Future<void> _pumpSidebar(
  WidgetTester tester,
  ProviderContainer container,
) async {
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
        home: const Scaffold(body: EditorSidebar()),
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
  });
}
