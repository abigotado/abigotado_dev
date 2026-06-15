import 'dart:ui';

import 'package:abigotado_dev/src/core/locale/locale_store.dart';
import 'package:abigotado_dev/src/core/locale/platform_locale_reader.dart';
import 'package:abigotado_dev/src/core/locale/supported_locale.dart';
import 'package:abigotado_dev/src/features/locale/state/locale_notifier.dart';
import 'package:abigotado_dev/src/features/locale/state/locale_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Hand-rolled fakes — no mockito needed (ports are tiny).
// ---------------------------------------------------------------------------

final class _FakeLocaleStore implements LocaleStore {
  _FakeLocaleStore({this.stored});

  final SupportedLocale? stored;

  int writeCalls = 0;
  int clearCalls = 0;
  SupportedLocale? lastWritten;

  @override
  SupportedLocale? read() => stored;

  @override
  Future<void> write(SupportedLocale locale) async {
    writeCalls++;
    lastWritten = locale;
  }

  @override
  Future<void> clear() async {
    clearCalls++;
  }
}

/// A [LocaleStore] whose write and clear always throw. The [stored] value is
/// intentionally provided as a required positional param so the analyzer
/// does not flag it as unused.
final class _ThrowingLocaleStore implements LocaleStore {
  const _ThrowingLocaleStore(this.stored);

  final SupportedLocale? stored;

  @override
  SupportedLocale? read() => stored;

  @override
  Future<void> write(SupportedLocale locale) async =>
      throw Exception('persist failure');

  @override
  Future<void> clear() async => throw Exception('clear failure');
}

/// A [LocaleStore] that throws on the first [write] call then succeeds
/// on every subsequent call. Used to verify that [LocaleState.persistFailed]
/// is reset on a successful follow-up write within the same notifier instance.
/// No stored choice — always reads null.
final class _FailOnceThenSucceedStore implements LocaleStore {
  _FailOnceThenSucceedStore();

  int _writeCalls = 0;
  SupportedLocale? lastWritten;

  @override
  SupportedLocale? read() => null;

  @override
  Future<void> write(SupportedLocale locale) async {
    _writeCalls++;
    if (_writeCalls == 1) throw Exception('first write fails');
    lastWritten = locale;
  }

  @override
  Future<void> clear() async {}
}

/// A [PlatformLocaleReader] with fixed locale list and timezone.
/// Both fields are positional so callers always specify them explicitly.
final class _FakePlatformLocaleReader implements PlatformLocaleReader {
  const _FakePlatformLocaleReader(this.locales, this.timeZoneId);

  @override
  final List<Locale> locales;

  @override
  final String? timeZoneId;
}

// ---------------------------------------------------------------------------
// Shared constant for "no locales, no timezone".
// ---------------------------------------------------------------------------

const _emptyReader = _FakePlatformLocaleReader([], null);

// ---------------------------------------------------------------------------
// Helper to build a container with both ports overridden.
// ---------------------------------------------------------------------------

ProviderContainer _makeContainer({
  required LocaleStore store,
  _FakePlatformLocaleReader reader = _emptyReader,
}) {
  return ProviderContainer(
    overrides: [
      localeStoreProvider.overrideWithValue(store),
      platformReaderProvider.overrideWithValue(reader),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('LocaleNotifier', () {
    group('build — initial state', () {
      test(
        'store has stored=ru → '
        'locale=ru.toLocale(), manualChoice=ru, persistFailed=false',
        () {
          final store = _FakeLocaleStore(stored: SupportedLocale.ru);
          final container = _makeContainer(store: store);
          addTearDown(container.dispose);

          final state = container.read(localeProvider);

          expect(
            state,
            equals(
              LocaleState(
                locale: SupportedLocale.ru.toLocale(),
                manualChoice: SupportedLocale.ru,
              ),
            ),
          );
        },
      );

      test(
        'store empty, reader=[es] → '
        'locale=es.toLocale(), manualChoice=null, persistFailed=false',
        () {
          final store = _FakeLocaleStore();
          final container = _makeContainer(
            store: store,
            reader: const _FakePlatformLocaleReader(
              [Locale('es')],
              null,
            ),
          );
          addTearDown(container.dispose);

          final state = container.read(localeProvider);

          expect(
            state,
            equals(const LocaleState(locale: Locale('es'))),
          );
        },
      );

      test('store empty, no reader locales, no tz → falls back to en', () {
        final store = _FakeLocaleStore();
        final container = _makeContainer(store: store);
        addTearDown(container.dispose);

        final state = container.read(localeProvider);

        expect(
          state,
          equals(const LocaleState(locale: Locale('en'))),
        );
      });
    });

    group('setLocale', () {
      test(
        'setLocale(es), store OK → '
        'locale=es.toLocale(), manualChoice=es, persistFailed=false',
        () async {
          final store = _FakeLocaleStore();
          final container = _makeContainer(store: store);
          addTearDown(container.dispose);

          await container
              .read(localeProvider.notifier)
              .setLocale(SupportedLocale.es);

          final state = container.read(localeProvider);
          expect(
            state,
            equals(
              LocaleState(
                locale: SupportedLocale.es.toLocale(),
                manualChoice: SupportedLocale.es,
              ),
            ),
          );
          expect(store.writeCalls, equals(1));
          expect(store.lastWritten, equals(SupportedLocale.es));
        },
      );

      test(
        'setLocale(es), store.write throws → '
        'locale still flips to es, manualChoice=es, persistFailed=true, '
        'no exception escapes',
        () async {
          const store = _ThrowingLocaleStore(null);
          final container = _makeContainer(store: store);
          addTearDown(container.dispose);

          // Must not throw.
          await expectLater(
            container
                .read(localeProvider.notifier)
                .setLocale(SupportedLocale.es),
            completes,
          );

          final state = container.read(localeProvider);
          expect(state.locale, equals(SupportedLocale.es.toLocale()));
          expect(state.manualChoice, equals(SupportedLocale.es));
          expect(state.persistFailed, isTrue);
        },
      );

      test(
        'setLocale(es) fails → persistFailed=true; '
        'setLocale(ru) succeeds on same notifier → '
        'persistFailed resets to false',
        () async {
          // Single notifier instance: first write throws (persistFailed=true),
          // second write succeeds (persistFailed must reset to false).
          final store = _FailOnceThenSucceedStore();
          final container = _makeContainer(store: store);
          addTearDown(container.dispose);

          // First call: store throws → locale flips but persistFailed=true.
          await container
              .read(localeProvider.notifier)
              .setLocale(SupportedLocale.es);

          expect(container.read(localeProvider).persistFailed, isTrue);

          // Second call on the SAME notifier: store succeeds → persistFailed
          // must be reset to false within setLocale's pre-await state update.
          await container
              .read(localeProvider.notifier)
              .setLocale(SupportedLocale.ru);

          final state = container.read(localeProvider);
          expect(state.locale, equals(SupportedLocale.ru.toLocale()));
          expect(state.manualChoice, equals(SupportedLocale.ru));
          expect(state.persistFailed, isFalse);
        },
      );
    });

    group('clearChoice', () {
      test(
        'clearChoice(), store OK, reader=[ru] → '
        'locale=ru.toLocale(), manualChoice=null, '
        'persistFailed=false, store.clear called once',
        () async {
          final store = _FakeLocaleStore(stored: SupportedLocale.es);
          final container = _makeContainer(
            store: store,
            reader: const _FakePlatformLocaleReader([Locale('ru')], null),
          );
          addTearDown(container.dispose);

          // Establish a manual choice first so there is something to clear.
          await container
              .read(localeProvider.notifier)
              .setLocale(SupportedLocale.es);

          await container.read(localeProvider.notifier).clearChoice();

          final state = container.read(localeProvider);
          expect(state.locale, equals(SupportedLocale.ru.toLocale()));
          expect(state.manualChoice, isNull);
          expect(state.persistFailed, isFalse);
          expect(store.clearCalls, equals(1));
        },
      );

      test(
        'clearChoice(), store.clear throws → '
        're-resolved locale applied, manualChoice=null, '
        'persistFailed=true, no exception escapes',
        () async {
          const store = _ThrowingLocaleStore(null);
          final container = _makeContainer(
            store: store,
            reader: const _FakePlatformLocaleReader([Locale('ru')], null),
          );
          addTearDown(container.dispose);

          await expectLater(
            container.read(localeProvider.notifier).clearChoice(),
            completes,
          );

          final state = container.read(localeProvider);
          // Locale is re-resolved (ru from platform).
          expect(state.locale, equals(SupportedLocale.ru.toLocale()));
          expect(state.manualChoice, isNull);
          expect(state.persistFailed, isTrue);
        },
      );
    });
  });
}
