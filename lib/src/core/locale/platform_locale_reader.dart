import 'package:flutter/widgets.dart';

/// Abstract port that supplies platform locale signals to the resolver.
///
/// Keeping this behind an interface lets tests inject a controlled list
/// of locales without touching [WidgetsBinding].
abstract interface class PlatformLocaleReader {
  /// The ordered list of locales reported by the host platform / browser.
  List<Locale> get locales;

  /// The IANA timezone identifier for the current device, or `null` when
  /// acquisition is deferred or unavailable.
  String? get timeZoneId;
}

/// [WidgetsBinding]-backed implementation of [PlatformLocaleReader].
///
/// Reads [WidgetsBinding.instance.platformDispatcher.locales] directly —
/// no `dart:js_interop`, no `package:web`, no `flutter_timezone`.
///
/// The constructor is `const` because this class holds no mutable state.
final class WidgetsBindingPlatformLocaleReader implements PlatformLocaleReader {
  /// Creates the reader.
  const WidgetsBindingPlatformLocaleReader();

  @override
  List<Locale> get locales =>
      WidgetsBinding.instance.platformDispatcher.locales;

  // Deferred: cross-platform flutter_timezone later.
  @override
  String? get timeZoneId => null;
}
