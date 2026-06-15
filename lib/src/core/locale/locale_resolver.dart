import 'dart:ui';

import 'package:abigotado_dev/src/core/locale/supported_locale.dart';

/// Resolves the effective [SupportedLocale] from the available signals,
/// in priority order:
///
/// 1. [stored] — a previously persisted manual user choice (always wins).
/// 2. [platformLocales] — the device/browser language list.
/// 3. [timeZoneId] — IANA timezone id used as a geographic heuristic.
/// 4. [SupportedLocale.en] — hard fallback.
///
/// Pure function — no side effects, no I/O. Unit-testable without a widget.
///
/// Stub — implemented in the GREEN phase.
SupportedLocale resolveLocale({
  SupportedLocale? stored,
  List<Locale> platformLocales = const [],
  String? timeZoneId,
}) => throw UnimplementedError();
