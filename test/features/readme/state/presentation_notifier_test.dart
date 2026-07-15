import 'package:abigotado_dev/src/features/readme/state/presentation_notifier.dart';
import 'package:abigotado_dev/src/features/readme/state/presentation_state.dart';
import 'package:abigotado_dev/src/features/readme/state/presentation_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helper: a fresh ProviderContainer with no overrides — PresentationNotifier
// has no injectable port (no store, no persistence; see the class doc).
// ---------------------------------------------------------------------------

ProviderContainer _makeContainer() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('PresentationNotifier', () {
    group('build', () {
      test('initial state is PresentationState(view: pitch)', () {
        final container = _makeContainer();

        final state = container.read(presentationProvider);

        expect(state, equals(const PresentationState()));
        expect(state.view, equals(PresentationView.pitch));
      });
    });

    group('openReadme', () {
      test('pitch → readme flips the view', () {
        final container = _makeContainer();

        container.read(presentationProvider.notifier).openReadme();

        expect(
          container.read(presentationProvider).view,
          equals(PresentationView.readme),
        );
      });

      test(
        'already readme → same state instance (no-op double-entry guard)',
        () {
          final container = _makeContainer();
          container.read(presentationProvider.notifier).openReadme();
          final before = container.read(presentationProvider);

          container.read(presentationProvider.notifier).openReadme();
          final after = container.read(presentationProvider);

          expect(
            identical(before, after),
            isTrue,
            reason:
                'calling openReadme while already on readme must not '
                'produce a new state instance — the sole caller '
                '(openReadme in readme_navigation.dart) relies on this to '
                'avoid arming a second LocalHistoryEntry',
          );
        },
      );
    });

    group('showPitch', () {
      test('readme → pitch flips the view back', () {
        final container = _makeContainer();
        container.read(presentationProvider.notifier)
          ..openReadme()
          ..showPitch();

        expect(
          container.read(presentationProvider).view,
          equals(PresentationView.pitch),
        );
      });

      test(
        'already pitch → same state instance (no-op guard)',
        () {
          final container = _makeContainer();
          final before = container.read(presentationProvider);

          container.read(presentationProvider.notifier).showPitch();
          final after = container.read(presentationProvider);

          expect(
            identical(before, after),
            isTrue,
            reason:
                'calling showPitch while already on pitch must not produce '
                'a new state instance',
          );
        },
      );
    });

    group('readmeOpenProvider', () {
      test('derives false → true → false across the transitions', () {
        final container = _makeContainer();

        expect(container.read(readmeOpenProvider), isFalse);

        container.read(presentationProvider.notifier).openReadme();
        expect(container.read(readmeOpenProvider), isTrue);

        container.read(presentationProvider.notifier).showPitch();
        expect(container.read(readmeOpenProvider), isFalse);
      });
    });
  });
}
