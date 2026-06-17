import 'dart:async';
import 'dart:developer' as developer;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart' as ul;

part 'url_launcher.g.dart';

/// Opens external URLs (mailto:/tel:/https). The I/O boundary: [open] swallows
/// and LOGS failures (it never throws to the UI), so callers fire-and-forget.
// ignore: one_member_abstracts
abstract interface class UrlLauncher {
  /// Attempts to open [url] in the system handler (browser, mail client,
  /// dialler). Never throws — failures are caught and logged.
  Future<void> open(Uri url);
}

/// Real launcher backed by url_launcher. Catches and logs both a thrown error
/// and a `false` return (mailto:/tel: can no-op silently) — never rethrows.
final class RealUrlLauncher implements UrlLauncher {
  /// Creates the production URL launcher.
  const RealUrlLauncher();

  @override
  Future<void> open(Uri url) async {
    try {
      final launched = await ul.launchUrl(
        url,
        mode: ul.LaunchMode.externalApplication,
      );
      if (!launched) {
        developer.log(
          'launchUrl returned false',
          name: 'UrlLauncher',
          error: url.toString(),
        );
      }
    } on Object catch (e, s) {
      developer.log(
        'launchUrl failed',
        name: 'UrlLauncher',
        error: e,
        stackTrace: s,
      );
    }
  }
}

/// Provides the [UrlLauncher] for the app.
///
/// Defaults to [RealUrlLauncher]; tests override it with a fake via
/// `urlLauncherProvider.overrideWithValue(fake)`.
@riverpod
UrlLauncher urlLauncher(Ref ref) => const RealUrlLauncher();
