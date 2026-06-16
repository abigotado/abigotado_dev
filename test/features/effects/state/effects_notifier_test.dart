import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/core/effects/effects_store.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Hand-rolled fakes — no mockito needed (port is tiny).
// ---------------------------------------------------------------------------

/// A configurable [EffectsStore] that records write and clear call counts.
final class _FakeEffectsStore implements EffectsStore {
  _FakeEffectsStore({this.stored});

  final EffectsMode? stored;

  int writeCalls = 0;
  int clearCalls = 0;
  EffectsMode? lastWritten;

  @override
  EffectsMode? read() => stored;

  @override
  Future<void> write(EffectsMode mode) async {
    writeCalls++;
    lastWritten = mode;
  }

  @override
  Future<void> clear() async {
    clearCalls++;
  }
}

/// An [EffectsStore] whose [write] and [clear] always throw.
///
/// The [stored] value is a required positional parameter so the analyzer does
/// not flag it as unused.
final class _ThrowingEffectsStore implements EffectsStore {
  const _ThrowingEffectsStore(this.stored);

  final EffectsMode? stored;

  @override
  EffectsMode? read() => stored;

  @override
  Future<void> write(EffectsMode mode) async =>
      throw Exception('persist failure');

  @override
  Future<void> clear() async => throw Exception('clear failure');
}

/// An [EffectsStore] that throws on the first [write] call then succeeds on
/// every subsequent call. Reads always return null (no stored choice).
final class _FailOnceThenSucceedStore implements EffectsStore {
  _FailOnceThenSucceedStore();

  int _writeCalls = 0;
  EffectsMode? lastWritten;

  @override
  EffectsMode? read() => null;

  @override
  Future<void> write(EffectsMode mode) async {
    _writeCalls++;
    if (_writeCalls == 1) throw Exception('first write fails');
    lastWritten = mode;
  }

  @override
  Future<void> clear() async {}
}

// ---------------------------------------------------------------------------
// Helper: build a ProviderContainer with effectsStoreProvider overridden.
// ---------------------------------------------------------------------------

ProviderContainer _makeContainer(EffectsStore store) {
  return ProviderContainer(
    overrides: [effectsStoreProvider.overrideWithValue(store)],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('EffectsNotifier', () {
    group('build — initial state', () {
      test('store empty → manualChoice=null, persistFailed=false', () {
        final store = _FakeEffectsStore();
        final container = _makeContainer(store);
        addTearDown(container.dispose);

        final state = container.read(effectsProvider);

        expect(
          state,
          equals(const EffectsState()),
        );
      });

      test('store returns lite → manualChoice=lite, persistFailed=false', () {
        final store = _FakeEffectsStore(stored: EffectsMode.lite);
        final container = _makeContainer(store);
        addTearDown(container.dispose);

        final state = container.read(effectsProvider);

        expect(
          state,
          equals(const EffectsState(manualChoice: EffectsMode.lite)),
        );
      });
    });

    group('setMode', () {
      test(
        'setMode(lite), store OK → manualChoice=lite, persistFailed=false, '
        'store.write called once with lite',
        () async {
          final store = _FakeEffectsStore();
          final container = _makeContainer(store);
          addTearDown(container.dispose);

          await container
              .read(effectsProvider.notifier)
              .setMode(EffectsMode.lite);

          final state = container.read(effectsProvider);
          expect(
            state,
            equals(const EffectsState(manualChoice: EffectsMode.lite)),
          );
          expect(store.writeCalls, equals(1));
          expect(store.lastWritten, equals(EffectsMode.lite));
        },
      );

      test(
        'setMode(lite), store.write throws → manualChoice=lite (still set), '
        'persistFailed=true, no exception escapes',
        () async {
          const store = _ThrowingEffectsStore(null);
          final container = _makeContainer(store);
          addTearDown(container.dispose);

          await expectLater(
            container.read(effectsProvider.notifier).setMode(EffectsMode.lite),
            completes,
          );

          final state = container.read(effectsProvider);
          expect(state.manualChoice, equals(EffectsMode.lite));
          expect(state.persistFailed, isTrue);
        },
      );

      test(
        'setMode(lite) fails → persistFailed=true; '
        'setMode(full) succeeds on same notifier → '
        'manualChoice=full, persistFailed resets to false',
        () async {
          final store = _FailOnceThenSucceedStore();
          final container = _makeContainer(store);
          addTearDown(container.dispose);

          await container
              .read(effectsProvider.notifier)
              .setMode(EffectsMode.lite);

          expect(container.read(effectsProvider).persistFailed, isTrue);

          await container
              .read(effectsProvider.notifier)
              .setMode(EffectsMode.full);

          final state = container.read(effectsProvider);
          expect(state.manualChoice, equals(EffectsMode.full));
          expect(state.persistFailed, isFalse);
          expect(store.lastWritten, equals(EffectsMode.full));
        },
      );
    });

    group('clearChoice', () {
      test(
        'clearChoice(), store OK → manualChoice=null, persistFailed=false, '
        'store.clear called once',
        () async {
          final store = _FakeEffectsStore(stored: EffectsMode.lite);
          final container = _makeContainer(store);
          addTearDown(container.dispose);

          // Establish a manual choice first so there is something to clear.
          await container
              .read(effectsProvider.notifier)
              .setMode(EffectsMode.lite);

          await container.read(effectsProvider.notifier).clearChoice();

          final state = container.read(effectsProvider);
          expect(state.manualChoice, isNull);
          expect(state.persistFailed, isFalse);
          expect(store.clearCalls, equals(1));
        },
      );

      test(
        'clearChoice(), store.clear throws → manualChoice=null (still cleared '
        'in-memory), persistFailed=true, no exception escapes',
        () async {
          const store = _ThrowingEffectsStore(null);
          final container = _makeContainer(store);
          addTearDown(container.dispose);

          await expectLater(
            container.read(effectsProvider.notifier).clearChoice(),
            completes,
          );

          final state = container.read(effectsProvider);
          expect(state.manualChoice, isNull);
          expect(state.persistFailed, isTrue);
        },
      );
    });
  });
}
