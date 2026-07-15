import 'package:abigotado_dev/src/app/theme/app_theme.dart';
import 'package:abigotado_dev/src/app/view/editor_scroll_host.dart';
import 'package:abigotado_dev/src/app/view/editor_shell.dart';
import 'package:abigotado_dev/src/app/view/pane_content.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/core/effects/effects_store.dart';
import 'package:abigotado_dev/src/core/locale/locale_store.dart';
import 'package:abigotado_dev/src/core/locale/platform_locale_reader.dart';
import 'package:abigotado_dev/src/core/locale/supported_locale.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/features/hero/state/build_scenario_notifier.dart';
import 'package:abigotado_dev/src/features/hero/state/build_scenario_state.dart';
import 'package:abigotado_dev/src/features/locale/state/locale_notifier.dart';
import 'package:abigotado_dev/src/features/readme/state/presentation_notifier.dart';
import 'package:abigotado_dev/src/features/readme/view/readme_navigation.dart';
import 'package:abigotado_dev/src/features/readme/view/readme_view.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes — the editor_shell_test.dart override set.
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

// Fixes the build scenario to a released snapshot so no hero tickers run —
// same precedent as editor_shell_test.dart's _FixedScenarioNotifier.
final class _FixedScenarioNotifier extends BuildScenarioNotifier {
  @override
  BuildScenarioState build() => const BuildScenarioState.released();
}

// ---------------------------------------------------------------------------
// Probe: exposes a real WidgetRef to the test, mirroring
// effects_toggle_test.dart's _EffectsModeHarness. Placed as a sibling of the
// README document so it shares the same BuildContext ancestry (Navigator,
// ProviderScope) without altering the widget tree the contract cares about.
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
// Helper: pump EditorShell(child: PaneContent()) at desktop 1280×800.
// ---------------------------------------------------------------------------

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  ValueNotifier<WidgetRef?>? refNotifier,
}) async {
  await tester.binding.setSurfaceSize(const Size(1280, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final container = ProviderContainer(
    overrides: [
      localeStoreProvider.overrideWithValue(const _FakeLocaleStore()),
      platformReaderProvider.overrideWithValue(
        const _FakePlatformLocaleReader(),
      ),
      effectsStoreProvider.overrideWithValue(const _FakeEffectsStore()),
      buildScenarioProvider.overrideWith(_FixedScenarioNotifier.new),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // The probe rides inside `builder` — same Navigator/route ancestry
        // as `home`, but outside the tree the A3 contract asserts on.
        builder: (context, child) => Stack(
          children: [
            ?child,
            if (refNotifier != null) _RefProbe(notifier: refNotifier),
          ],
        ),
        home: const EditorShell(child: PaneContent()),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return container;
}

void main() {
  group('README browser-Back contract (A3)', () {
    testWidgets(
      '1. initial: readmeOpen false, Navigator.canPop false',
      (tester) async {
        final container = await _pumpApp(tester);

        expect(container.read(readmeOpenProvider), isFalse);
        expect(
          Navigator.of(tester.element(find.byType(EditorScrollHost))).canPop(),
          isFalse,
        );
      },
    );

    testWidgets(
      '2. tap entry chip → readmeOpen true, ReadmeView present, '
      'EditorScrollHost absent, Navigator.canPop true',
      (tester) async {
        final container = await _pumpApp(tester);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(EditorScrollHost)),
        );

        await tester.tap(find.text(l10n.rm_entry_chip));
        await tester.pumpAndSettle();

        expect(container.read(readmeOpenProvider), isTrue);
        expect(find.byType(ReadmeView), findsOneWidget);
        expect(find.byType(EditorScrollHost), findsNothing);
        expect(
          Navigator.of(tester.element(find.byType(ReadmeView))).canPop(),
          isTrue,
          reason:
              'openReadme must arm a LocalHistoryEntry so the web engine '
              'intercepts the next browser-Back press',
        );
      },
    );

    testWidgets(
      '3. handlePopRoute() → readmeOpen false, ReadmeView gone, EditorShell '
      'still present, canPop false',
      (tester) async {
        final container = await _pumpApp(tester);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(EditorScrollHost)),
        );

        await tester.tap(find.text(l10n.rm_entry_chip));
        await tester.pumpAndSettle();

        final handled = await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(
          handled,
          isTrue,
          reason:
              'the LocalHistoryEntry must consume the pop — the app must not '
              'report itself unable to handle browser-Back',
        );
        expect(container.read(readmeOpenProvider), isFalse);
        expect(find.byType(ReadmeView), findsNothing);
        expect(find.byType(EditorShell), findsOneWidget);
        expect(
          Navigator.of(tester.element(find.byType(EditorScrollHost))).canPop(),
          isFalse,
        );
      },
    );

    testWidgets(
      '4. reopen → tap ✕ → readmeOpen false AND canPop false (entry '
      'consumed); a further handlePopRoute() is a no-op, no exception',
      (tester) async {
        final container = await _pumpApp(tester);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(EditorScrollHost)),
        );

        await tester.tap(find.text(l10n.rm_entry_chip));
        await tester.pumpAndSettle();

        await tester.tap(find.bySemanticsLabel(l10n.rm_close_hint));
        await tester.pumpAndSettle();

        expect(container.read(readmeOpenProvider), isFalse);
        expect(
          Navigator.of(tester.element(find.byType(EditorScrollHost))).canPop(),
          isFalse,
          reason:
              'the ✕ must pop via Navigator.maybePop so the local history '
              'entry is consumed — no stale entry left behind',
        );

        final secondHandled = await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(
          secondHandled,
          isFalse,
          reason:
              'no stale LocalHistoryEntry remains — a further pop must not '
              're-close anything',
        );
        expect(tester.takeException(), isNull);
        expect(container.read(readmeOpenProvider), isFalse);
      },
    );

    testWidgets(
      '5. double-open guard: open, then call openReadme(context, ref) again '
      'while open → still exactly one entry — one maybePop() resolves true '
      '→ pitch + canPop false',
      (tester) async {
        final refNotifier = ValueNotifier<WidgetRef?>(null);
        addTearDown(refNotifier.dispose);
        final container = await _pumpApp(tester, refNotifier: refNotifier);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(EditorScrollHost)),
        );

        await tester.tap(find.text(l10n.rm_entry_chip));
        await tester.pumpAndSettle();

        final readmeContext = tester.element(find.byType(ReadmeView));
        final ref = refNotifier.value;
        expect(ref, isNotNull, reason: 'the probe must have captured a ref');
        openReadme(readmeContext, ref!);
        await tester.pumpAndSettle();

        expect(container.read(readmeOpenProvider), isTrue);

        final resolved = await Navigator.of(
          tester.element(find.byType(ReadmeView)),
        ).maybePop();
        await tester.pumpAndSettle();

        expect(
          resolved,
          isTrue,
          reason:
              'exactly one LocalHistoryEntry must be armed even after a '
              'double-open — a single maybePop must close the README',
        );
        expect(container.read(readmeOpenProvider), isFalse);
        expect(
          Navigator.of(tester.element(find.byType(EditorScrollHost))).canPop(),
          isFalse,
        );
      },
    );

    testWidgets(
      '6. a second Navigator.maybePop() from pitch resolves false — '
      'nothing left to pop',
      (tester) async {
        await _pumpApp(tester);

        final resolved = await Navigator.of(
          tester.element(find.byType(EditorScrollHost)),
        ).maybePop();
        await tester.pumpAndSettle();

        expect(
          resolved,
          isFalse,
          reason:
              'on the default pitch path there is no local history entry to '
              'pop — the app would hand back to the platform',
        );
      },
    );
  });
}
