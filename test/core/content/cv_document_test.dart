import 'dart:io';

import 'package:abigotado_dev/src/core/content/cv_document.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Pure content guard tests for the résumé PDF links. `flutter test` runs with
// the package root as the working directory, so `web/` is reachable here.
// ---------------------------------------------------------------------------

void main() {
  group('cvPdfUrl', () {
    test('ru gets the Russian résumé', () {
      expect(cvPdfUrl('ru'), equals(cvPdfRuUrl));
    });

    test('en gets the English résumé', () {
      expect(cvPdfUrl('en'), equals(cvPdfEnUrl));
    });

    test('es, which has no résumé of its own, falls back to English', () {
      expect(cvPdfUrl('es'), equals(cvPdfEnUrl));
    });
  });

  group('published files', () {
    // A renamed or missing PDF would deploy a dead link: the URL path must
    // resolve to a real file under web/, which the build copies verbatim.
    for (final url in [cvPdfEnUrl, cvPdfRuUrl]) {
      test('$url is served from web/', () {
        final uri = Uri.parse(url);

        expect(uri.scheme, equals('https'));
        expect(uri.host, equals('abigotado.dev'));
        expect(
          File('web${uri.path}').existsSync(),
          isTrue,
          reason: 'web${uri.path} must exist for $url to resolve',
        );
      });
    }
  });
}
