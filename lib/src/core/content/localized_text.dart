import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';

/// A reference to a localized string — a function that, given the active
/// [AppLocalizations], returns the resolved text for the current locale.
///
/// Lets a `const` content entry carry a *reference* to an arb getter (e.g.
/// `(l10n) => l10n.pcm`) instead of a baked-in string: a mistyped key is a
/// compile error, and the value resolves at the call site with the live
/// `l10n`. This intentionally depends on the generated `AppLocalizations`
/// delegate — that is the i18n contract, not a UI import — so it lives in
/// `core/content/` as a shared, feature-agnostic seam (changelog reuses it).
typedef LocalizedText = String Function(AppLocalizations l10n);
