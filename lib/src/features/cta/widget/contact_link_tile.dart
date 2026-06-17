import 'dart:async';

import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/core/launcher/url_launcher.dart';
import 'package:abigotado_dev/src/features/cta/content/contact_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A tappable chip that opens [ContactLink.url] via [UrlLauncher].
///
/// Renders as a bordered chip styled to match the terminal aesthetic.
/// Tap target is at least 44 px tall (WCAG 2.5.5).
/// Semantics: announced as both a button and a link.
class ContactLinkTile extends ConsumerWidget {
  /// Creates a contact link tile for [link].
  const ContactLinkTile({required this.link, super.key});

  /// The contact entry this tile represents.
  final ContactLink link;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      link: true,
      label: link.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => unawaited(
          ref.read(urlLauncherProvider).open(Uri.parse(link.url)),
        ),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            link.label,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: AppColors.accentTeal,
            ),
          ),
        ),
      ),
    );
  }
}
