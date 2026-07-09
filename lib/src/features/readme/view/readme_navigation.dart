import 'package:abigotado_dev/src/features/readme/state/presentation_notifier.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the README document, arming browser-Back to close it.
///
/// This is the single entry point into `PresentationView.readme` — every
/// README trigger (`ReadmeEntryChip`, `ReadmeInvitationCard`,
/// `ReadmeSidebarRow`) calls this instead of touching
/// [PresentationNotifier.openReadme] directly.
///
/// ## The A3 contract: why a [LocalHistoryEntry] is required
///
/// abigotado.dev is a single-route Flutter Web app: [Navigator] never pushes
/// a second [Route] for the README (it is a same-route presentation flip, not
/// a navigation). On a single-route stack `Navigator.canPop()` reports
/// `false`. On Flutter's web engine, `canPop() == false` tells the browser
/// history integration "this app cannot handle a pop" — the *next*
/// browser-Back press is left unintercepted and the tab navigates away from
/// the site entirely, rather than closing the README. This was verified
/// empirically against the running app and confirmed against the Flutter SDK
/// source (`Navigator`/`RouterDelegate` web history handling): a bare
/// `openReadme` that only flips state, with no local history entry, breaks
/// Back.
///
/// [LocalHistoryEntry] fixes this: [ModalRoute.addLocalHistoryEntry] pushes a
/// local history record onto the *current* route (no new route, no URL
/// change) and flips [Navigator.canPop] to `true` for as long as the entry is
/// live. That is enough to arm the web engine's browser-Back interception. A
/// Back press now pops the local entry — invoking [LocalHistoryEntry.onRemove]
/// — instead of leaving the page.
///
/// `onRemove` is wired to [PresentationNotifier.showPitch] and is the ONLY
/// caller of that method: every in-app close path (the README tab's ✕, a
/// sidebar tap while the README is open) must call
/// `Navigator.of(context).maybePop()` instead of `showPitch()` directly, so
/// that popping the local entry and flipping the presentation state always
/// happen together — never one without the other.
///
/// `impliesAppBarDismissal` is `false`: this app has no `AppBar` whose
/// dismissal behavior the entry should drive.
///
/// ## Guards
///
/// No-ops if the README is already open (double-entry guard) — calling this
/// twice in a row must not arm two [LocalHistoryEntry] instances, which would
/// require two Back presses to leave the README.
void openReadme(BuildContext context, WidgetRef ref) =>
    throw UnimplementedError('green pass');
