import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Global test bootstrap — Flutter's test runner invokes this for every suite
/// under `test/`.
///
/// It loads the Flutter SDK's bundled **Roboto** so golden tests render real
/// glyphs instead of the Ahem placeholder box font. The TTF ships inside the
/// pinned SDK (`bin/cache/artifacts/material_fonts/Roboto-Regular.ttf`), so its
/// bytes are identical on macOS-local and the CI Linux runner (both run Flutter
/// 3.44.0) — the only cross-OS variance left is the rasterizer's anti-aliasing,
/// which is exactly why golden baselines are authored on Linux CI only.
///
/// Loading a font is additive and side-effect-free for the ~387 non-golden
/// tests (none assert on glyph pixels), so this hook is safe for the whole
/// suite. If the SDK font can't be located it degrades gracefully to Ahem.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadRoboto();
  await testMain();
}

Future<void> _loadRoboto() async {
  final ttf = _materialFontFile('Roboto-Regular.ttf');
  if (ttf == null || !ttf.existsSync()) return; // graceful fallback to Ahem
  final data = ByteData.sublistView(await ttf.readAsBytes());

  // Register under the default family AND 'monospace' (the terminal/code bodies
  // use `fontFamily: 'monospace'`, which has no SDK file and would otherwise
  // fall back to Ahem boxes). Both map to Roboto: deterministic and legible.
  for (final family in const ['Roboto', 'monospace']) {
    final loader = FontLoader(family)..addFont(Future<ByteData>.value(data));
    await loader.load();
  }
}

/// Resolves `<flutter-sdk>/bin/cache/artifacts/material_fonts/<name>` from the
/// running test executable (`flutter_tester` lives under `<sdk>/bin/cache/...`),
/// which works identically under `fvm flutter test` and `subosito/flutter-action`
/// without relying on an env var. Falls back to `FLUTTER_ROOT`.
File? _materialFontFile(String name) {
  String? root;
  final exe = Platform.resolvedExecutable;
  final marker =
      '${Platform.pathSeparator}bin'
      '${Platform.pathSeparator}cache${Platform.pathSeparator}';
  final idx = exe.indexOf(marker);
  if (idx != -1) root = exe.substring(0, idx);
  root ??= Platform.environment['FLUTTER_ROOT'];
  if (root == null) return null;
  return File(
    <String>[
      root,
      'bin',
      'cache',
      'artifacts',
      'material_fonts',
      name,
    ].join(Platform.pathSeparator),
  );
}
