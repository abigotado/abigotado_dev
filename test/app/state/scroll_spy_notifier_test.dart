import 'package:abigotado_dev/src/app/state/scroll_spy_notifier.dart';
import 'package:abigotado_dev/src/app/widget/editor_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// ScrollSpyNotifier has no injected dependencies, so ProviderContainer needs
// no overrides. Each test creates its own container and registers a teardown.
// ---------------------------------------------------------------------------

void main() {
  group('ScrollSpyNotifier', () {
    // -------------------------------------------------------------------------
    group('setActiveFile', () {
      test('distinct value updates activeFile', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Default is fileHero; pubspec is a distinct value.
        container
            .read(scrollSpyProvider.notifier)
            .setActiveFile(EditorFile.pubspec);

        expect(
          container.read(scrollSpyProvider).activeFile,
          equals(EditorFile.pubspec),
        );
      });

      test('same value is a no-op (state instance unchanged)', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Read the initial state — default activeFile is fileHero.
        final before = container.read(scrollSpyProvider);

        // setActiveFile with the same value must not allocate a new state.
        container
            .read(scrollSpyProvider.notifier)
            .setActiveFile(EditorFile.fileHero);

        final after = container.read(scrollSpyProvider);
        // Equatable equality: same props → same value under ==.
        expect(after, equals(before));
      });
    });

    // -------------------------------------------------------------------------
    group('requestScrollTo', () {
      test('emits ScrollRequest with the target', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container
            .read(scrollSpyProvider.notifier)
            .requestScrollTo(EditorFile.changelog);

        final request = container.read(scrollSpyProvider).scrollRequest;
        expect(request, isNotNull);
        expect(request!.target, equals(EditorFile.changelog));
      });

      // Repeat-tap dead-button guard: the `id` field exists so two consecutive
      // requests to the same file are distinct Equatable values and both fire
      // in the scroll host's ref.listen callback.
      test('two taps on the same file produce different ids', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container
            .read(scrollSpyProvider.notifier)
            .requestScrollTo(EditorFile.pubspec);
        final id1 = container.read(scrollSpyProvider).scrollRequest!.id;

        container
            .read(scrollSpyProvider.notifier)
            .requestScrollTo(EditorFile.pubspec);
        final id2 = container.read(scrollSpyProvider).scrollRequest!.id;

        expect(id2, isNot(equals(id1)));
        expect(
          container.read(scrollSpyProvider).scrollRequest!.target,
          equals(EditorFile.pubspec),
        );
      });
    });

    // -------------------------------------------------------------------------
    group('clearScrollRequest', () {
      test('clears a pending request to null', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container
            .read(scrollSpyProvider.notifier)
            .requestScrollTo(EditorFile.metrics);
        expect(container.read(scrollSpyProvider).scrollRequest, isNotNull);

        container.read(scrollSpyProvider.notifier).clearScrollRequest();

        expect(container.read(scrollSpyProvider).scrollRequest, isNull);
      });

      test('is a no-op when already null', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // No request has been dispatched — scrollRequest is already null.
        expect(container.read(scrollSpyProvider).scrollRequest, isNull);

        // Must not throw and state must remain consistent.
        container.read(scrollSpyProvider.notifier).clearScrollRequest();

        expect(container.read(scrollSpyProvider).scrollRequest, isNull);
      });
    });

    // -------------------------------------------------------------------------
    group('activeEditorFileValue', () {
      // The derived provider is real, but driving it through setActiveFile
      // (which is stubbed) makes this test red. This is the meaningful
      // end-to-end check of the thin selector.
      test('follows setActiveFile', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container
            .read(scrollSpyProvider.notifier)
            .setActiveFile(EditorFile.metrics);

        expect(
          container.read(activeEditorFileValueProvider),
          equals(EditorFile.metrics),
        );
      });
    });

    // -------------------------------------------------------------------------
    group('revealSections', () {
      test(
        'revealSections grows revealed and sets hasMeasured',
        () {
          // Call revealSections twice; after the second call revealed must
          // contain the union of both sets and hasMeasured must be true.
          //
          // RED: revealSections throws UnimplementedError.
          final container = ProviderContainer();
          addTearDown(container.dispose);

          container.read(scrollSpyProvider.notifier).revealSections({
            EditorFile.fileHero,
          });

          container.read(scrollSpyProvider.notifier).revealSections({
            EditorFile.fileHero,
            EditorFile.metrics,
          });

          final state = container.read(scrollSpyProvider);
          expect(
            state.revealed,
            equals(const {EditorFile.fileHero, EditorFile.metrics}),
            reason:
                'revealed must be the union of both calls — latch means it '
                'only grows',
          );
          expect(
            state.hasMeasured,
            isTrue,
            reason: 'hasMeasured must flip to true after revealSections',
          );
        },
      );

      test(
        'first revealSections emits even when next equals default {}',
        () {
          // Fresh container: revealed={}, hasMeasured=false.
          // Calling revealSections({}) must flip hasMeasured to true even
          // though the revealed set is unchanged.
          //
          // Falsifiability: this catches an implementation that guards on
          //   `setEquals(next, state.revealed)` WITHOUT checking `hasMeasured`.
          // Such an implementation would drop the first call and never set
          // hasMeasured=true.
          //
          // RED: revealSections throws UnimplementedError.
          final container = ProviderContainer();
          addTearDown(container.dispose);

          // Confirm the default state.
          expect(
            container.read(scrollSpyProvider).hasMeasured,
            isFalse,
            reason:
                'precondition: hasMeasured must be false on fresh container',
          );

          container.read(scrollSpyProvider.notifier).revealSections(const {});

          expect(
            container.read(scrollSpyProvider).hasMeasured,
            isTrue,
            reason:
                'first revealSections call must always emit and flip '
                'hasMeasured to true, even when next == {} (the default)',
          );
        },
      );
    });

    // -------------------------------------------------------------------------
    group('sectionRevealed selector', () {
      test(
        'sectionRevealed: true for all before measurement; '
        'reflects set after revealSections',
        () {
          // Part 1 — BEFORE measurement (hasMeasured=false):
          // sectionRevealedProvider(contacts) must return true (the
          // !hasMeasured guard makes all sections visible before the first
          // measurement so there is no flash-of-hidden-content).
          //
          // This part is GREEN — the selector is real and !hasMeasured is
          // true on fresh container.
          //
          // Part 2 — AFTER revealSections({fileHero}):
          // sectionRevealed(contacts)==false, sectionRevealed(fileHero)==true.
          //
          // The after-part is RED (revealSections throws).
          // The test is a single unit asserting the full contract.
          final container = ProviderContainer();
          addTearDown(container.dispose);

          // Part 1: before measurement — all sections report revealed=true.
          expect(
            container.read(sectionRevealedProvider(EditorFile.contacts)),
            isTrue,
            reason:
                'before any measurement hasMeasured=false, so sectionRevealed '
                'must return true for every file (no flash of hidden content)',
          );

          // Part 2: after revealSections — only fileHero was revealed.
          // RED: revealSections throws UnimplementedError.
          container.read(scrollSpyProvider.notifier).revealSections({
            EditorFile.fileHero,
          });

          expect(
            container.read(sectionRevealedProvider(EditorFile.fileHero)),
            isTrue,
            reason: 'fileHero was passed to revealSections → must be true',
          );
          expect(
            container.read(sectionRevealedProvider(EditorFile.contacts)),
            isFalse,
            reason:
                'contacts was NOT passed to revealSections and hasMeasured '
                'is now true → must be false',
          );
        },
      );
    });
  });
}
