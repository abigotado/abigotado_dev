import 'package:abigotado_dev/src/app/state/hot_reload_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// HotReloadNotifier has no injected dependencies; ProviderContainer needs no
// overrides. Each test creates its own container and registers a teardown so
// the container is disposed after every case regardless of outcome.
// ---------------------------------------------------------------------------

void main() {
  group('HotReloadNotifier', () {
    group('build', () {
      test('initial state is 0 (no pulse has fired)', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(container.read(hotReloadProvider), equals(0));
      });
    });

    group('pulse', () {
      test('one pulse → id is greater than the initial value of 0', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final before = container.read(hotReloadProvider);
        container.read(hotReloadProvider.notifier).pulse();
        final after = container.read(hotReloadProvider);

        expect(
          after,
          greaterThan(before),
          reason:
              'pulse must strictly increase the pulse id so SectionFlash '
              'watchers see a new value and re-fire the flash',
        );
      });

      // Repeat-tap re-fire guarantee: two consecutive pulses must each produce
      // a distinct, strictly-increasing id. Mirrors the scroll-spy monotonic-id
      // idiom ("two requests → different ids").
      //
      // Falsifiable: an implementation that clamps to a fixed value (e.g.
      // always emits 1) would fail the second expect.
      test(
        'two pulse() calls → two distinct, strictly-increasing ids '
        '(repeat-tap re-fire guarantee)',
        () {
          final container = ProviderContainer();
          addTearDown(container.dispose);

          container.read(hotReloadProvider.notifier).pulse();
          final id1 = container.read(hotReloadProvider);

          container.read(hotReloadProvider.notifier).pulse();
          final id2 = container.read(hotReloadProvider);

          expect(
            id1,
            isNot(equals(id2)),
            reason: 'id after second pulse must differ from id after first',
          );
          expect(
            id2,
            greaterThan(id1),
            reason:
                'the pulse id must be monotonically increasing so each tap '
                'is distinguishable from the last',
          );
        },
      );
    });
  });
}
