import 'package:abigotado_dev/src/app/theme/app_theme.dart';
import 'package:abigotado_dev/src/app/view/landing_page.dart';
import 'package:flutter/material.dart';

/// Root widget for abigotado.dev.
class AbigotadoApp extends StatelessWidget {
  /// Creates the root application widget.
  const AbigotadoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nikita Kovalenko — abigotado.dev',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const LandingPage(),
    );
  }
}
