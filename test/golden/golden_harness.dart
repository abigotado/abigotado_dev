import 'package:abigotado_dev/src/app/theme/app_theme.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/core/effects/effects_store.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shared scaffolding for the golden harness (not a `_test.dart` suite).
///
/// Every golden renders a section in **lite** effects mode — the documented
/// reduced-motion fallback — so the tree settles to a deterministic,
/// ticker-free frame (`pumpAndSettle`) with no animation, hover, or
/// scroll-reveal in flight. We golden the lite render by construction; the
/// static sections look identical in full mode at rest.

/// An [EffectsStore] pinned to lite, so `effectsModeOf` resolves to lite
/// regardless of viewport. Mirrors the fake duplicated across the widget tests.
final class _LiteEffectsStore implements EffectsStore {
  const _LiteEffectsStore();

  @override
  EffectsMode? read() => EffectsMode.lite;

  @override
  Future<void> write(EffectsMode mode) async {}

  @override
  Future<void> clear() async {}
}

/// Pumps [section] in a minimal dark-themed, localized, lite-mode tree at a
/// fixed [surface] size, then settles. The section sits in a
/// [SingleChildScrollView] so it lays out at its intrinsic height without
/// overflow; golden the section's own finder (not the surface) to capture it.
Future<void> pumpGoldenSection(
  WidgetTester tester, {
  required Widget section,
  required Size surface,
  Locale locale = const Locale('en'),
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        effectsStoreProvider.overrideWithValue(const _LiteEffectsStore()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(child: section),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
