import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/app/theme/app_sizing.dart';
import 'package:abigotado_dev/src/app/view/editor_pane.dart';
import 'package:abigotado_dev/src/app/view/editor_sidebar.dart';
import 'package:abigotado_dev/src/app/view/editor_status_bar.dart';
import 'package:abigotado_dev/src/app/widget/background/living_background.dart';
import 'package:abigotado_dev/src/app/widget/traffic_lights.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// The editor-IDE shell that frames the landing content.
///
/// The responsive split is driven by [LayoutBuilder] constraints:
/// `constraints.maxWidth >= AppSizing.editorBreakpoint` selects desktop.
///
/// Desktop (≥ 900 px):
/// ```dart
/// Column(children: [
///   _EditorTitleBar(),              // TrafficLights + title
///   Expanded(child: Row(children: [
///     EditorSidebar(),              // fixed 172 px file-explorer panel
///     Expanded(child: EditorPane(child: child)),
///   ])),
///   EditorStatusBar(),
/// ])
/// ```
///
/// Mobile (< 900 px):
/// ```dart
/// Column(children: [
///   _EditorTitleBar(compact: true),
///   Expanded(child: EditorPane(child: child)),
///   EditorStatusBar(compact: true),
/// ])
/// ```
class EditorShell extends StatelessWidget {
  /// Creates the editor shell.
  const EditorShell({required this.child, super.key});

  /// The main page content displayed inside the shell.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: LivingBackground()),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop =
                    constraints.maxWidth >= AppSizing.editorBreakpoint;

                if (isDesktop) {
                  return Column(
                    children: [
                      const _EditorTitleBar(),
                      Expanded(
                        child: Row(
                          children: [
                            const EditorSidebar(),
                            Expanded(child: EditorPane(child: child)),
                          ],
                        ),
                      ),
                      const EditorStatusBar(),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      const _EditorTitleBar(compact: true),
                      Expanded(child: EditorPane(child: child)),
                      const EditorStatusBar(compact: true),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The full-width title bar shown at the top of the editor shell.
///
/// Contains [TrafficLights] on the left and a filename/name title centred in
/// the remaining space. In [compact] mode (mobile) the title shows only
/// `"abigotado.dev"`; in full mode (desktop) it appends the localised author
/// name: `"abigotado.dev — {name}"`. The release tag lives in
/// [EditorStatusBar] rather than here — keeping it in one place avoids
/// duplicate "RELEASE" text in the widget tree.
class _EditorTitleBar extends StatelessWidget {
  const _EditorTitleBar({this.compact = false});

  final bool compact;

  static const _titleStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    color: AppColors.textMuted,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = compact ? 'abigotado.dev' : 'abigotado.dev — ${l10n.name}';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        spacing: 12,
        children: [
          const TrafficLights(),
          Expanded(
            child: Text(
              title,
              style: _titleStyle,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
