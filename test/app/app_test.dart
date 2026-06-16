import 'package:abigotado_dev/src/app/app.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/core/effects/effects_store.dart';
import 'package:abigotado_dev/src/core/locale/locale_store.dart';
import 'package:abigotado_dev/src/core/locale/platform_locale_reader.dart';
import 'package:abigotado_dev/src/core/locale/supported_locale.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/features/locale/state/locale_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes — deterministic, no real platform / storage.
// ---------------------------------------------------------------------------

/// Returns [EffectsMode.lite] so the hero calls `skip()` (not `start()`) and
/// allocates no [AnimationController]s — making `pumpAndSettle` safe.
///
/// Without this override the hero's perpetual spinner/cursor [AnimationController]s
/// repeat forever and `pumpAndSettle` would time out.
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
  _FakeLocaleStore({this.stored});

  final SupportedLocale? stored;

  @override
  SupportedLocale? read() => stored;

  @override
  Future<void> write(SupportedLocale locale) async {}

  @override
  Future<void> clear() async {}
}

/// A [PlatformLocaleReader] whose locale list and timezone are fixed at
/// construction time. Both fields must be provided explicitly at each call
/// site so the analyzer does not flag them as unused optional parameters.
final class _FakePlatformLocaleReader implements PlatformLocaleReader {
  const _FakePlatformLocaleReader(this.locales, this.timeZoneId);

  @override
  final List<Locale> locales;

  @override
  final String? timeZoneId;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _noLocales = <Locale>[];

// ---------------------------------------------------------------------------
// Helper: pump the full AbigotadoApp at a fixed 1280×800 surface.
// ---------------------------------------------------------------------------

Future<void> _pumpApp(
  WidgetTester tester, {
  required LocaleStore store,
  required PlatformLocaleReader reader,
}) async {
  await tester.binding.setSurfaceSize(const Size(1280, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localeStoreProvider.overrideWithValue(store),
        platformReaderProvider.overrideWithValue(reader),
        effectsStoreProvider.overrideWithValue(const _FakeEffectsStore()),
      ],
      child: const AbigotadoApp(),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AbigotadoApp', () {
    group('chrome', () {
      testWidgets('renders without debug banner', (tester) async {
        await _pumpApp(
          tester,
          store: _FakeLocaleStore(),
          reader: const _FakePlatformLocaleReader(_noLocales, null),
        );

        final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(app.debugShowCheckedModeBanner, isFalse);
      });
    });

    group('locale — auto resolution', () {
      testWidgets(
        'no stored, no platform → en fallback → shows Nikita Kovalenko',
        (tester) async {
          await _pumpApp(
            tester,
            store: _FakeLocaleStore(),
            reader: const _FakePlatformLocaleReader(_noLocales, null),
          );

          expect(find.text('Nikita Kovalenko'), findsOneWidget);
        },
      );
    });

    group('locale — stored preference', () {
      testWidgets(
        'stored=ru → shows Никита Коваленко',
        (tester) async {
          await _pumpApp(
            tester,
            store: _FakeLocaleStore(stored: SupportedLocale.ru),
            reader: const _FakePlatformLocaleReader(_noLocales, null),
          );

          expect(find.text('Никита Коваленко'), findsOneWidget);
        },
      );

      testWidgets(
        'stored=en → shows Nikita Kovalenko',
        (tester) async {
          await _pumpApp(
            tester,
            store: _FakeLocaleStore(stored: SupportedLocale.en),
            reader: const _FakePlatformLocaleReader(_noLocales, null),
          );

          expect(find.text('Nikita Kovalenko'), findsOneWidget);
        },
      );
    });
  });
}
