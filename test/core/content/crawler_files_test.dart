import 'dart:convert';
import 'dart:io';

import 'package:abigotado_dev/src/core/content/contact_links.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Guards for the crawler-facing files in web/. Flutter paints to a canvas, so
// search engines read only these — a drifted link or a malformed JSON-LD block
// fails silently in production.
// ---------------------------------------------------------------------------

void main() {
  final html = File('web/index.html').readAsStringSync();
  final canonical = RegExp(
    '<link rel="canonical" href="([^"]+)">',
  ).firstMatch(html)!.group(1)!;

  group('crawler files', () {
    group('JSON-LD Person', () {
      final blocks = RegExp(
        r'<script type="application/ld\+json">([\s\S]*?)</script>',
      ).allMatches(html).toList();

      test('index.html → one parseable JSON-LD block', () {
        expect(blocks, hasLength(1));
        expect(() => jsonDecode(blocks.single.group(1)!), returnsNormally);
      });

      test('Person → canonical url, sameAs equals the https contacts', () {
        final person =
            jsonDecode(blocks.single.group(1)!) as Map<String, Object?>;
        final https = [
          for (final link in contactLinks)
            if (link.url.startsWith('https://')) link.url,
        ];

        expect(person['@type'], equals('Person'));
        expect(person['url'], equals(canonical));
        expect(person['sameAs'], unorderedEquals(https));
      });

      test('Person → carries no direct contact or location fields', () {
        final person =
            jsonDecode(blocks.single.group(1)!) as Map<String, Object?>;

        for (final key in ['telephone', 'email', 'address', 'homeLocation']) {
          expect(person, isNot(contains(key)), reason: '$key must stay out');
        }
      });
    });

    test('robots.txt → allows all, names the sitemap', () {
      final robots = File('web/robots.txt').readAsStringSync();

      expect(
        robots,
        matches(RegExp(r'^User-agent:\s*\*\s*$', multiLine: true)),
      );
      expect(
        robots,
        isNot(matches(RegExp(r'^Disallow:\s*/\s*$', multiLine: true))),
      );
      expect(robots, contains('Sitemap: ${canonical}sitemap.xml'));
    });

    test('sitemap.xml → lists the canonical URL', () {
      final sitemap = File('web/sitemap.xml').readAsStringSync();

      expect(sitemap, contains('<loc>$canonical</loc>'));
    });
  });
}
