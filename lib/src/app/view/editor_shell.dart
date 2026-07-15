import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:abigotado_dev/src/app/theme/app_sizing.dart';
import 'package:abigotado_dev/src/app/view/editor_pane.dart';
import 'package:abigotado_dev/src/app/view/editor_sidebar.dart';
import 'package:abigotado_dev/src/app/view/editor_status_bar.dart';
import 'package:abigotado_dev/src/app/widget/background/living_background.dart';
import 'package:abigotado_dev/src/app/widget/traffic_lights.dart';
import 'package:abigotado_dev/src/features/hero/widget/debug_release_banner.dart';
import 'package:abigotado_dev/src/features/hotreload/widget/hot_reload_fab.dart';
import 'package:abigotado_dev/src/features/readme/state/presentation_notifier.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    // The DEBUG/RELEASE ribbon wraps the whole editor window — it sits on the
    // top-end corner of the entire site, not on the hero terminal panel.
    return Scaffold(
      body: DebugReleaseBanner(
        child: Stack(
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
                              Expanded(child: _PaneWithFab(child: child)),
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
                        Expanded(child: _PaneWithFab(child: child)),
                        const EditorStatusBar(compact: true),
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
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

/// The editor content pane with the floating hot-reload [HotReloadFab] pinned
/// to its bottom-right corner.
///
/// The FAB lives in a [Stack] scoped to the content pane — above the status bar
/// (the pane sits in the layout above it) and clear of the status-bar controls,
/// so it floats over scrolling content without ever colliding with the compact
/// status bar's wrapping locale/effects controls. Used by both layout branches.
///
/// The FAB is hidden while the README is open ([readmeOpenProvider]) — the
/// hot-reload "rebuild" flash it triggers is a pitch-only conceit that has no
/// meaning over the README document.
class _PaneWithFab extends ConsumerWidget {
  const _PaneWithFab({required this.child});

  /// Gap between the FAB and the pane's bottom-right edges.
  static const double _fabMargin = 16;

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readmeOpen = ref.watch(readmeOpenProvider);

    return Stack(
      children: [
        EditorPane(child: child),
        if (!readmeOpen)
          const Positioned(
            right: _fabMargin,
            bottom: _fabMargin,
            child: HotReloadFab(),
          ),
      ],
    );
  }
}
