import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/core/locale/locale_store.dart';
import 'package:abigotado_dev/src/core/locale/platform_locale_reader.dart';
import 'package:abigotado_dev/src/core/locale/supported_locale.dart';
import 'package:abigotado_dev/src/features/locale/state/locale_notifier.dart';
import 'package:abigotado_dev/src/features/locale/widget/locale_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Hand-rolled fakes — no mockito.
// ---------------------------------------------------------------------------

final class _FakeLocaleStore implements LocaleStore {
  _FakeLocaleStore({this.stored});

  final SupportedLocale? stored;

  int writeCalls = 0;
  SupportedLocale? lastWritten;

  @override
  SupportedLocale? read() => stored;

  @override
  Future<void> write(SupportedLocale locale) async {
    writeCalls++;
    lastWritten = locale;
  }

  @override
  Future<void> clear() async {}
}

/// A [PlatformLocaleReader] with fixed, positional parameters so callers
/// always specify them explicitly and the analyzer does not flag them as
/// unused optional parameters.
final class _FakePlatformLocaleReader implements PlatformLocaleReader {
  const _FakePlatformLocaleReader(this.locales, this.timeZoneId);

  @override
  final List<Locale> locales;

  @override
  final String? timeZoneId;
}

const _emptyReader = _FakePlatformLocaleReader([], null);

// ---------------------------------------------------------------------------
// Helper: pump LocaleSwitcher inside a minimal Material+ProviderScope tree.
// ---------------------------------------------------------------------------

Future<void> _pumpSwitcher(
  WidgetTester tester, {
  required LocaleStore store,
  _FakePlatformLocaleReader reader = _emptyReader,
}) async {
  await tester.binding.setSurfaceSize(const Size(600, 200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localeStoreProvider.overrideWithValue(store),
        platformReaderProvider.overrideWithValue(reader),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: LocaleSwitcher()),
        ),
      ),
    ),
  );
  // Settle AnimatedContainer transitions inside each segment.
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('LocaleSwitcher', () {
    group('rendering', () {
      testWidgets('shows three segments labelled RU, EN, ES', (tester) async {
        final store = _FakeLocaleStore();
        await _pumpSwitcher(tester, store: store);

        expect(find.text('RU'), findsOneWidget);
        expect(find.text('EN'), findsOneWidget);
        expect(find.text('ES'), findsOneWidget);
      });
    });

    group('active segment highlighting', () {
      testWidgets(
        'auto-resolved en → EN text color is AppColors.accentTeal; '
        'RU and ES text color is AppColors.textMuted',
        (tester) async {
          final store = _FakeLocaleStore();
          await _pumpSwitcher(tester, store: store);

          final enText = tester.widget<Text>(find.text('EN'));
          final ruText = tester.widget<Text>(find.text('RU'));
          final esText = tester.widget<Text>(find.text('ES'));

          expect(enText.style?.color, equals(AppColors.accentTeal));
          expect(ruText.style?.color, equals(AppColors.textMuted));
          expect(esText.style?.color, equals(AppColors.textMuted));
        },
      );

      testWidgets(
        'stored=ru → RU text color is AppColors.accentTeal; '
        'EN and ES text color is AppColors.textMuted',
        (tester) async {
          final store = _FakeLocaleStore(stored: SupportedLocale.ru);
          await _pumpSwitcher(tester, store: store);

          final ruText = tester.widget<Text>(find.text('RU'));
          final enText = tester.widget<Text>(find.text('EN'));
          final esText = tester.widget<Text>(find.text('ES'));

          expect(ruText.style?.color, equals(AppColors.accentTeal));
          expect(enText.style?.color, equals(AppColors.textMuted));
          expect(esText.style?.color, equals(AppColors.textMuted));
        },
      );

      testWidgets(
        'stored=es → ES text color is AppColors.accentTeal; '
        'RU and EN text color is AppColors.textMuted',
        (tester) async {
          final store = _FakeLocaleStore(stored: SupportedLocale.es);
          await _pumpSwitcher(tester, store: store);

          final esText = tester.widget<Text>(find.text('ES'));
          final ruText = tester.widget<Text>(find.text('RU'));
          final enText = tester.widget<Text>(find.text('EN'));

          expect(esText.style?.color, equals(AppColors.accentTeal));
          expect(ruText.style?.color, equals(AppColors.textMuted));
          expect(enText.style?.color, equals(AppColors.textMuted));
        },
      );
    });

    group('tap interaction', () {
      testWidgets(
        'tapping ES when auto-en active → locale transitions to es, '
        'store write recorded',
        (tester) async {
          final store = _FakeLocaleStore();
          await _pumpSwitcher(tester, store: store);

          await tester.tap(find.text('ES'));
          await tester.pumpAndSettle();

          expect(store.writeCalls, equals(1));
          expect(store.lastWritten, equals(SupportedLocale.es));

          final esText = tester.widget<Text>(find.text('ES'));
          final enText = tester.widget<Text>(find.text('EN'));
          expect(esText.style?.color, equals(AppColors.accentTeal));
          expect(enText.style?.color, equals(AppColors.textMuted));
        },
      );

      testWidgets(
        'tapping RU when stored=es → locale transitions to ru, '
        'store write recorded',
        (tester) async {
          final store = _FakeLocaleStore(stored: SupportedLocale.es);
          await _pumpSwitcher(tester, store: store);

          await tester.tap(find.text('RU'));
          await tester.pumpAndSettle();

          expect(store.writeCalls, equals(1));
          expect(store.lastWritten, equals(SupportedLocale.ru));
        },
      );

      testWidgets(
        'tapping EN when stored=ru → locale transitions to en, '
        'store write recorded',
        (tester) async {
          final store = _FakeLocaleStore(stored: SupportedLocale.ru);
          await _pumpSwitcher(tester, store: store);

          await tester.tap(find.text('EN'));
          await tester.pumpAndSettle();

          expect(store.writeCalls, equals(1));
          expect(store.lastWritten, equals(SupportedLocale.en));
        },
      );
    });
  });
}
