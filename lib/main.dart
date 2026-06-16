import 'package:abigotado_dev/src/app/app.dart';
import 'package:abigotado_dev/src/core/effects/effects_store.dart';
import 'package:abigotado_dev/src/core/locale/locale_store.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/features/locale/state/locale_notifier.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        localeStoreProvider.overrideWithValue(
          SharedPreferencesLocaleStore(prefs),
        ),
        effectsStoreProvider.overrideWithValue(
          SharedPreferencesEffectsStore(prefs),
        ),
      ],
      child: const AbigotadoApp(),
    ),
  );
}
