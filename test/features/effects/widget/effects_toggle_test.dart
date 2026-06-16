import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/core/effects/effects_store.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/features/effects/widget/effects_toggle.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Hand-rolled fakes — no mockito.
// ---------------------------------------------------------------------------

/// A configurable [EffectsStore] that records write and clear calls.
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

// ---------------------------------------------------------------------------
// Helper: pump EffectsToggle inside a minimal, locale-aware Material tree.
//
// [mediaQueryData] controls `disableAnimations` and `size` so tests never
// read the real platform. [store] is injected via ProviderScope.
// ---------------------------------------------------------------------------

Future<void> _pumpToggle(
  WidgetTester tester, {
  required _FakeEffectsStore store,
  required MediaQueryData mediaQueryData,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [effectsStoreProvider.overrideWithValue(store)],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        // Force en so label assertions are locale-independent.
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: mediaQueryData,
          child: const Scaffold(
            body: Center(child: EffectsToggle()),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// effectsModeOf harness — a ConsumerWidget that calls effectsModeOf and
// writes the result into a ValueNotifier so tests can inspect it.
// ---------------------------------------------------------------------------

class _EffectsModeHarness extends ConsumerWidget {
  const _EffectsModeHarness({required this.notifier});

  final ValueNotifier<EffectsMode?> notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    notifier.value = effectsModeOf(context, ref);
    return const SizedBox.shrink();
  }
}

Future<EffectsMode?> _resolveMode(
  WidgetTester tester, {
  required _FakeEffectsStore store,
  required MediaQueryData mediaQueryData,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 600));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final notifier = ValueNotifier<EffectsMode?>(null);
  addTearDown(notifier.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [effectsStoreProvider.overrideWithValue(store)],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: mediaQueryData,
          child: Scaffold(
            body: _EffectsModeHarness(notifier: notifier),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return notifier.value;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('effectsModeOf (harness)', () {
    testWidgets(
      'no manual choice, disableAnimations=true, width=1280 → lite',
      (tester) async {
        final mode = await _resolveMode(
          tester,
          store: _FakeEffectsStore(),
          mediaQueryData: const MediaQueryData(
            disableAnimations: true,
            size: Size(1280, 800),
          ),
        );
        expect(mode, equals(EffectsMode.lite));
      },
    );

    testWidgets(
      'no manual choice, width=375 (compact), no reduced-motion → lite',
      (tester) async {
        final mode = await _resolveMode(
          tester,
          store: _FakeEffectsStore(),
          mediaQueryData: const MediaQueryData(size: Size(375, 812)),
        );
        expect(mode, equals(EffectsMode.lite));
      },
    );

    testWidgets(
      'no manual choice, width=1280, no reduced-motion → full',
      (tester) async {
        final mode = await _resolveMode(
          tester,
          store: _FakeEffectsStore(),
          mediaQueryData: const MediaQueryData(size: Size(1280, 800)),
        );
        expect(mode, equals(EffectsMode.full));
      },
    );

    testWidgets(
      'stored manualChoice=lite, width=1280, no reduced-motion → '
      'lite (manual wins over auto-full)',
      (tester) async {
        final mode = await _resolveMode(
          tester,
          store: _FakeEffectsStore(stored: EffectsMode.lite),
          mediaQueryData: const MediaQueryData(size: Size(1280, 800)),
        );
        expect(mode, equals(EffectsMode.lite));
      },
    );

    testWidgets(
      'stored manualChoice=full, disableAnimations=true, width=375 → '
      'full (manual wins over OS+compact)',
      (tester) async {
        final mode = await _resolveMode(
          tester,
          store: _FakeEffectsStore(stored: EffectsMode.full),
          mediaQueryData: const MediaQueryData(
            disableAnimations: true,
            size: Size(375, 812),
          ),
        );
        expect(mode, equals(EffectsMode.full));
      },
    );
  });

  group('EffectsToggle', () {
    group('rendering — label and color', () {
      testWidgets(
        'effective=full → "Effects on" in AppColors.accentAmber, '
        'no "Effects off"',
        (tester) async {
          await _pumpToggle(
            tester,
            store: _FakeEffectsStore(),
            mediaQueryData: const MediaQueryData(size: Size(1280, 800)),
          );

          final text = tester.widget<Text>(find.text('Effects on'));
          expect(text.style?.color, equals(AppColors.accentAmber));
          expect(find.text('Effects off'), findsNothing);
        },
      );

      testWidgets(
        'effective=lite (reduced-motion) → "Effects off" in '
        'AppColors.textMuted, no "Effects on"',
        (tester) async {
          await _pumpToggle(
            tester,
            store: _FakeEffectsStore(),
            mediaQueryData: const MediaQueryData(
              disableAnimations: true,
              size: Size(1280, 800),
            ),
          );

          final text = tester.widget<Text>(find.text('Effects off'));
          expect(text.style?.color, equals(AppColors.textMuted));
          expect(find.text('Effects on'), findsNothing);
        },
      );

      testWidgets(
        'effective=lite (compact width) → "Effects off", no "Effects on"',
        (tester) async {
          await _pumpToggle(
            tester,
            store: _FakeEffectsStore(),
            mediaQueryData: const MediaQueryData(size: Size(375, 812)),
          );

          expect(find.text('Effects off'), findsOneWidget);
          expect(find.text('Effects on'), findsNothing);
        },
      );

      testWidgets(
        'stored manualChoice=lite, normal width, no reduced-motion → '
        '"Effects off" (manual wins)',
        (tester) async {
          await _pumpToggle(
            tester,
            store: _FakeEffectsStore(stored: EffectsMode.lite),
            mediaQueryData: const MediaQueryData(size: Size(1280, 800)),
          );

          expect(find.text('Effects off'), findsOneWidget);
          expect(find.text('Effects on'), findsNothing);
        },
      );

      testWidgets(
        'stored manualChoice=full, reduced-motion+compact → '
        '"Effects on" (manual wins over OS+compact)',
        (tester) async {
          await _pumpToggle(
            tester,
            store: _FakeEffectsStore(stored: EffectsMode.full),
            mediaQueryData: const MediaQueryData(
              disableAnimations: true,
              size: Size(375, 812),
            ),
          );

          expect(find.text('Effects on'), findsOneWidget);
          expect(find.text('Effects off'), findsNothing);
        },
      );
    });

    group('tap target', () {
      testWidgets(
        'AnimatedContainer has minHeight >= 44 (mobile-first tap target)',
        (tester) async {
          await _pumpToggle(
            tester,
            store: _FakeEffectsStore(),
            mediaQueryData: const MediaQueryData(size: Size(1280, 800)),
          );

          final container = tester.widget<AnimatedContainer>(
            find.byType(AnimatedContainer),
          );
          // constraints is non-nullable on AnimatedContainer.
          expect(
            container.constraints!.minHeight,
            greaterThanOrEqualTo(44),
          );
        },
      );
    });

    group('tap interaction', () {
      testWidgets(
        'tapping when effective=full → setMode(lite) called, '
        'store.write=1 with lite, label becomes "Effects off"',
        (tester) async {
          final store = _FakeEffectsStore();
          await _pumpToggle(
            tester,
            store: store,
            mediaQueryData: const MediaQueryData(size: Size(1280, 800)),
          );

          await tester.tap(find.byType(InkWell));
          await tester.pumpAndSettle();

          expect(store.writeCalls, equals(1));
          expect(store.lastWritten, equals(EffectsMode.lite));
          expect(find.text('Effects off'), findsOneWidget);
        },
      );

      testWidgets(
        'tapping when effective=lite (reduced-motion) → setMode(full) called, '
        'store.write=1 with full, label becomes "Effects on"',
        (tester) async {
          final store = _FakeEffectsStore();
          await _pumpToggle(
            tester,
            store: store,
            mediaQueryData: const MediaQueryData(
              disableAnimations: true,
              size: Size(1280, 800),
            ),
          );

          await tester.tap(find.byType(InkWell));
          await tester.pumpAndSettle();

          expect(store.writeCalls, equals(1));
          expect(store.lastWritten, equals(EffectsMode.full));
          // Manual full overrides reduced-motion → label flips to "Effects on".
          expect(find.text('Effects on'), findsOneWidget);
        },
      );

      testWidgets(
        'tapping twice (full → lite → full): '
        'store.write=2, lastWritten=full, label "Effects on"',
        (tester) async {
          final store = _FakeEffectsStore();
          await _pumpToggle(
            tester,
            store: store,
            mediaQueryData: const MediaQueryData(size: Size(1280, 800)),
          );

          await tester.tap(find.byType(InkWell));
          await tester.pumpAndSettle();

          await tester.tap(find.byType(InkWell));
          await tester.pumpAndSettle();

          expect(store.writeCalls, equals(2));
          expect(store.lastWritten, equals(EffectsMode.full));
          expect(find.text('Effects on'), findsOneWidget);
        },
      );
    });
  });
}
