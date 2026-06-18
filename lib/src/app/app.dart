import 'package:abigotado_dev/src/app/theme/app_theme.dart';
import 'package:abigotado_dev/src/app/view/editor_shell.dart';
import 'package:abigotado_dev/src/app/view/landing_page.dart';
import 'package:abigotado_dev/src/features/locale/state/locale_notifier.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root widget for abigotado.dev.
class AbigotadoApp extends ConsumerWidget {
  /// Creates the root application widget.
  const AbigotadoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider).locale;

    return MaterialApp(
      onGenerateTitle: (context) =>
          '${AppLocalizations.of(context).name} — abigotado.dev',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: const EditorShell(
        child: SingleChildScrollView(child: LandingPage()),
      ),
    );
  }
}
