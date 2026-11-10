/// The downloadable résumé PDFs, served as static files from `web/cv/`.
///
/// **To update the résumé:** replace the PDFs in `web/cv/` (keep the file
/// names). They are rendered from the canonical résumé with the phone numbers
/// removed — the repo is public, so no phone number may land in it. CI runs
/// `tool/check_cv_pdfs.sh` on every push to enforce that.
///
/// Absolute `https://` URLs, like every other contact target: the launch
/// works the same on every platform, not only on the web build.
const String cvPdfEnUrl = 'https://abigotado.dev/cv/Nikita_Kovalenko_CV_en.pdf';

/// The Russian résumé PDF. See [cvPdfEnUrl].
const String cvPdfRuUrl = 'https://abigotado.dev/cv/Nikita_Kovalenko_CV_ru.pdf';

/// The Spanish résumé PDF. See [cvPdfEnUrl].
const String cvPdfEsUrl = 'https://abigotado.dev/cv/Nikita_Kovalenko_CV_es.pdf';

/// The résumé PDF for [languageCode]. Every supported locale has its own; an
/// unknown code gets the English one, matching the app's fallback locale.
String cvPdfUrl(String languageCode) => switch (languageCode) {
  'ru' => cvPdfRuUrl,
  'es' => cvPdfEsUrl,
  _ => cvPdfEnUrl,
};
