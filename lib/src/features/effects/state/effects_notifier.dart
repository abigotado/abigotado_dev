import 'dart:developer' as developer;

import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/core/effects/effects_resolver.dart';
import 'package:abigotado_dev/src/core/effects/effects_store.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'effects_notifier.g.dart';

/// Breakpoint below which the viewport is considered compact (mobile).
///
/// Mirrors the responsive layout breakpoint used across the app.
const double kCompactWidth = 600;

/// Provides the [EffectsStore] implementation.
///
/// Must be overridden at the [ProviderScope] root before the app starts —
/// see `main.dart`. Test suites override it with a fake or in-memory store.
@riverpod
EffectsStore effectsStore(Ref ref) =>
    throw UnimplementedError('override at bootstrap/in tests');

/// Manages the effects-mode state for abigotado.dev.
///
/// Reads the initial manual choice from the [EffectsStore] on startup.
/// Effective mode (full vs lite) is resolved at the widget layer via
/// [effectsModeOf], which combines the manual choice with OS reduced-motion
/// and viewport-width signals.
///
/// Persist failures are surfaced via [EffectsState.persistFailed] rather
/// than thrown to the UI.
@riverpod
class EffectsNotifier extends _$EffectsNotifier {
  /// Monotonically-increasing counter used to guard against stale async
  /// completions clobbering newer state (see [setMode] / [clearChoice]).
  int _opVersion = 0;

  @override
  EffectsState build() {
    final stored = ref.watch(effectsStoreProvider).read();
    return EffectsState(manualChoice: stored);
  }

  /// Applies [mode] immediately (in-memory) and persists it to
  /// [EffectsStore]. If the persist step fails, [EffectsState.persistFailed]
  /// is set to `true` but the mode flip is preserved.
  Future<void> setMode(EffectsMode mode) async {
    final op = ++_opVersion;
    state = state.copyWith(manualChoice: mode, persistFailed: false);
    try {
      await ref.read(effectsStoreProvider).write(mode);
    } on Object catch (e, s) {
      developer.log(
        'effects persist failed',
        error: e,
        stackTrace: s,
        name: 'EffectsNotifier',
      );
      if (!ref.mounted || op != _opVersion) return;
      state = state.copyWith(persistFailed: true);
    }
  }

  /// Clears the stored manual choice and reverts to automatic resolution.
  /// If the store clear fails, [EffectsState.persistFailed] is set to `true`
  /// but the re-resolved mode is still applied.
  Future<void> clearChoice() async {
    final op = ++_opVersion;
    // Construct directly to null out manualChoice — copyWith's sentinel
    // distinguishes "omit" from "pass null", so we can't use copyWith here.
    state = const EffectsState();
    try {
      await ref.read(effectsStoreProvider).clear();
    } on Object catch (e, s) {
      developer.log(
        'effects clear failed',
        error: e,
        stackTrace: s,
        name: 'EffectsNotifier',
      );
      if (!ref.mounted || op != _opVersion) return;
      state = state.copyWith(persistFailed: true);
    }
  }
}

/// Resolves the effective [EffectsMode] for the current context.
///
/// Reads `effectsProvider` for the manual choice,
/// [MediaQuery.disableAnimationsOf] for the OS reduced-motion signal, and
/// [MediaQuery.sizeOf] width against [kCompactWidth] for the viewport signal.
/// Delegates to [resolveEffectsMode] for the final decision.
///
/// This is a widget-layer composition helper — call from `build` only.
EffectsMode effectsModeOf(BuildContext context, WidgetRef ref) {
  final manualChoice = ref.watch(effectsProvider).manualChoice;
  final osReducedMotion = MediaQuery.disableAnimationsOf(context);
  final isCompact = MediaQuery.sizeOf(context).width < kCompactWidth;
  return resolveEffectsMode(
    osReducedMotion: osReducedMotion,
    isCompact: isCompact,
    manualChoice: manualChoice,
  );
}
