import 'package:abigotado_dev/src/core/content/localized_text.dart';
import 'package:flutter/foundation.dart';

/// One work-experience entry in the README document.
///
/// [org] is a [LocalizedText] DELIBERATELY, unlike `ContactLink.label` or
/// `CareerEntry.version`: some organizations localize (e.g. «Цифровые
/// технологии и платформы» ↔ "Digital Technologies & Platforms") while
/// invariant brands (FinHarbor, Somnio Software, CPI Technologies GmbH) simply
/// repeat the same string across locales — the same convention as
/// `CareerEntry.org`'s `ch_org1`..`ch_org6` arb keys.
///
/// [url] is `null` in stage 1 — every org renders as plain text. Stage 3
/// fills this in once each org gets a real link target; `ReadmeBody` already
/// branches on `entry.url` so that stage lands without touching this type.
@immutable
class ExperienceEntry {
  /// Creates a work-experience entry.
  const ExperienceEntry({
    required this.org,
    required this.role,
    required this.summary,
    required this.achievements,
    this.url,
  });

  /// The organization name, localized (see class doc for why).
  final LocalizedText org;

  /// The role held at [org], localized (e.g. "Flutter-разработчик" /
  /// "Flutter Developer").
  final LocalizedText role;

  /// A one-sentence summary of the engagement, localized.
  final LocalizedText summary;

  /// The 3–4 strongest achievement bullets for this entry, localized.
  final List<LocalizedText> achievements;

  /// Optional link target for the org name. `null` in stage 1 (rendered as
  /// plain text); stage 3 fills this in per entry.
  final String? url;
}
