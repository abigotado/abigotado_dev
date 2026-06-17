// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'url_launcher.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the [UrlLauncher] for the app.
///
/// Defaults to [RealUrlLauncher]; tests override it with a fake via
/// `urlLauncherProvider.overrideWithValue(fake)`.

@ProviderFor(urlLauncher)
final urlLauncherProvider = UrlLauncherProvider._();

/// Provides the [UrlLauncher] for the app.
///
/// Defaults to [RealUrlLauncher]; tests override it with a fake via
/// `urlLauncherProvider.overrideWithValue(fake)`.

final class UrlLauncherProvider
    extends $FunctionalProvider<UrlLauncher, UrlLauncher, UrlLauncher>
    with $Provider<UrlLauncher> {
  /// Provides the [UrlLauncher] for the app.
  ///
  /// Defaults to [RealUrlLauncher]; tests override it with a fake via
  /// `urlLauncherProvider.overrideWithValue(fake)`.
  UrlLauncherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'urlLauncherProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$urlLauncherHash();

  @$internal
  @override
  $ProviderElement<UrlLauncher> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UrlLauncher create(Ref ref) {
    return urlLauncher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UrlLauncher value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UrlLauncher>(value),
    );
  }
}

String _$urlLauncherHash() => r'9cb9b8c1c0106f29c258e3a7be8cce0f2034b414';
