import 'package:abigotado_dev/src/features/readme/state/presentation_notifier.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The sticky README preview panel — a fixed-width third column shown on
/// wide desktop viewports, to the right of the editor pane.
///
/// A permanent, condensed taste of `README.md`: the document's header,
/// collaboration line, and about paragraph (via `ReadmeBody.headerCrop`),
/// plus a CTA that opens the full document. Mounted directly as a `Row`
/// child by `EditorShell`'s desktop branch, gated on
/// `constraints.maxWidth >= AppSizing.readmePanelBreakpoint` — this widget
/// itself knows nothing about that breakpoint; it only decides, once
/// mounted, whether to render its content or hide (see below).
///
/// ## Reclaiming its own width
///
/// The panel — not an external wrapper — owns its fixed
/// `AppSizing.readmePanelWidth` (380 px) via its own `Container`. This is
/// deliberate: [readmeOpenProvider] flips to `true` once the full document
/// replaces the pane (`PaneContent`'s pitch → readme swap), at which point a
/// second, smaller copy of the same content sitting beside it would be
/// redundant. Because the width lives INSIDE this widget rather than on an
/// ancestor, the guard clause that returns `SizedBox.shrink()` for that case
/// genuinely reclaims the 380 px for the content pane's `Expanded`
/// neighbour — an external `SizedBox`/width wrapper around
/// `ReadmePreviewPanel` would keep reserving the width even while this
/// widget renders nothing, so `EditorShell` must never add one.
///
/// ## Intended GREEN render (implemented in the green pass)
///
/// ```dart
/// @override
/// Widget build(BuildContext context, WidgetRef ref) {
///   if (ref.watch(readmeOpenProvider)) return const SizedBox.shrink();
///
///   final l10n = AppLocalizations.of(context);
///   return Container(
///     width: AppSizing.readmePanelWidth,
///     decoration: const BoxDecoration(
///       color: AppColors.surface, // matches EditorSidebar's chrome
///       border: Border(left: BorderSide(color: AppColors.border)),
///     ),
///     child: Column(
///       crossAxisAlignment: CrossAxisAlignment.stretch,
///       children: [
///         _PanelHeader(title: l10n.rm_tab_title, label: l10n.rm_panel_label),
///         Expanded(
///           child: SingleChildScrollView(
///             child: Padding(
///               padding: const EdgeInsets.all(16),
///               child: Column(
///                 spacing: 16,
///                 children: [
///                   const ReadmeBody.headerCrop(),
///                   _PanelCta(),
///                 ],
///               ),
///             ),
///           ),
///         ),
///       ],
///     ),
///   );
/// }
/// ```
///
/// `_PanelHeader` is a chrome strip mirroring `EditorSidebar`'s header
/// treatment and `ReadmeView`'s `_ReadmeTab` strip: a `Container` with an
/// `AppColors.surface` background and a bottom hairline `AppColors.border`,
/// `EdgeInsets.symmetric(horizontal: 12, vertical: 8)` padding, and a `Row`
/// showing the monospace `l10n.rm_tab_title` ("README.md", `textPrimary`,
/// the same style as `_ReadmeTab`'s title) on the left and the muted
/// `l10n.rm_panel_label` ("preview") caption on the right — the VS Code
/// "preview" tab-marker convention this panel is styled after.
///
/// `_PanelCta` is a private `Widget` class (never a `_buildX` method):
/// `Semantics(button: true)` → `InkWell(onTap: () => openReadme(context,
/// ref))` → `Container(constraints: BoxConstraints(minHeight: 44),
/// decoration: BoxDecoration(border: Border.all(color: AppColors.accentTeal),
/// borderRadius: BorderRadius.circular(8)))` → `Row(spacing: 8)` of
/// `Text(l10n.rm_panel_open)` and a trailing arrow glyph. Same shape as
/// `ReadmeInvitationCard`'s idiom, but with an accent-teal border in place of
/// that card's plain hairline `AppColors.border` — the stronger invitation
/// appropriate to a permanently-visible panel. Tap target ≥ 44 px (WCAG
/// 2.5.5). It MUST funnel through `openReadme` (`readme_navigation.dart`) —
/// the same single entry point as every other README trigger, which arms the
/// A3 `LocalHistoryEntry` browser-Back contract — and must NEVER touch
/// `presentationProvider`/`PresentationNotifier` directly.
///
/// Fully static: no `AnimatedX` widget, no `AnimationController`, no
/// ticker — the panel has no motion of its own to gate behind lite mode.
///
/// ## THIS PASS
///
/// `build` returns [SizedBox.shrink] unconditionally — the
/// `readmeOpenProvider` guard, header, crop, and CTA all wait for the green
/// pass to implement the tree sketched above.
class ReadmePreviewPanel extends ConsumerWidget {
  /// Creates the README preview panel.
  const ReadmePreviewPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const SizedBox.shrink();
}
