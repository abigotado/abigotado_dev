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

/// The résumé PDF for [languageCode]. A locale without its own résumé (es)
/// gets the English one — its `cv_pdf` label says so.
String cvPdfUrl(String languageCode) => switch (languageCode) {
  'ru' => cvPdfRuUrl,
  _ => cvPdfEnUrl,
};
