import 'package:flutter/foundation.dart';

/// One contact entry for the CTA contacts panel.
///
/// [label] is the visible brand string or address literal — not localized,
/// because phone numbers, handles, and email addresses are invariant across
/// locales.
///
/// [url] is the launch target — a `mailto:`, `tel:`, or `https:` URI.
///
/// **Not equatable by design:** contact links are static configuration, never
/// compared at runtime. Edit `contactLinks` in `cta_content.dart` to update
/// the list — no widget code changes needed.
@immutable
class ContactLink {
  /// Creates a contact link entry.
  const ContactLink({required this.label, required this.url});

  /// Visible label — brand name, number, or email literal. Never localized.
  final String label;

  /// Launch target: `mailto:`, `tel:`, or `https:` URI string.
  final String url;
}
