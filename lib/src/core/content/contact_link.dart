import 'package:flutter/foundation.dart';

/// One contact entry for the CTA contacts panel.
///
/// [label] is the visible brand string or address literal — the static
/// entries are not localized, because handles and email addresses are
/// invariant across locales.
///
/// [url] is the launch target — a `mailto:` or `https:` URI.
///
/// **Not equatable by design:** contact links are static configuration, never
/// compared at runtime. Edit `contactLinks` in `contact_links.dart` to update
/// the list — no widget code changes needed.
///
/// Lives in `core/content/` (promoted from the `cta` feature) because
/// `ReadmeBody`'s contacts section reuses [ContactLink] and `ContactLinkTile`
/// alongside `MergeCtaSection` — a shared, feature-agnostic seam rather than
/// a single feature's private content.
@immutable
class ContactLink {
  /// Creates a contact link entry.
  const ContactLink({required this.label, required this.url});

  /// Visible label. Usually a brand name or email literal; an entry built at
  /// runtime may pass a localized one.
  final String label;

  /// Launch target: a `mailto:` or `https:` URI string.
  final String url;
}
