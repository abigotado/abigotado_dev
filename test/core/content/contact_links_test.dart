import 'package:abigotado_dev/src/core/content/contact_links.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Pure content guard tests — no widgets, no BuildContext, no mocks.
//
// These PASS from birth — they guard the owner's hard rules against the
// real contactLinks list. A future content edit that violates a rule will
// break one of these tests.
// ---------------------------------------------------------------------------

void main() {
  group('contactLinks', () {
    // -----------------------------------------------------------------------
    // Count guard — the owner finalized exactly 5 contacts (no raw phone
    // numbers: Telegram replaces tel: links so no number lands in the repo).
    // -----------------------------------------------------------------------
    group('count', () {
      test('exactly 5 entries', () {
        expect(contactLinks.length, equals(5));
      });
    });

    // -----------------------------------------------------------------------
    // URL scheme guard — every entry must use a known safe scheme. No tel: by
    // design (phone numbers are deliberately kept out of the public repo).
    // -----------------------------------------------------------------------
    group('url scheme', () {
      const validSchemes = ['mailto:', 'https://'];

      test('no tel: link (no phone number in the repo)', () {
        for (final link in contactLinks) {
          expect(
            link.url.startsWith('tel:'),
            isFalse,
            reason: 'phone numbers must not appear in any contact url',
          );
        }
      });

      test('each url has a valid scheme', () {
        for (final link in contactLinks) {
          final hasValidScheme = validSchemes.any(link.url.startsWith);
          expect(
            hasValidScheme,
            isTrue,
            reason:
                'url "${link.url}" (label: "${link.label}") must start with '
                'one of: ${validSchemes.join(", ")}',
          );
        }
      });
    });

    // -----------------------------------------------------------------------
    // Specific URL presence — exact values the owner committed to.
    // -----------------------------------------------------------------------
    group('specific urls present', () {
      final urls = contactLinks.map((l) => l.url).toList();

      test('email entry: mailto:nik.koval.89@gmail.com', () {
        expect(
          urls,
          contains('mailto:nik.koval.89@gmail.com'),
          reason: 'email contact link must be present',
        );
      });

      test('GitHub entry: https://github.com/Abigotado', () {
        expect(
          urls,
          contains('https://github.com/Abigotado'),
          reason: 'GitHub contact link must be present',
        );
      });

      test('GitLab entry: https://gitlab.com/Abigotado', () {
        expect(
          urls,
          contains('https://gitlab.com/Abigotado'),
          reason: 'GitLab contact link must be present',
        );
      });

      test(
        'LinkedIn entry: https://www.linkedin.com/in/nik-koval-abigotado/',
        () {
          expect(
            urls,
            contains('https://www.linkedin.com/in/nik-koval-abigotado/'),
            reason: 'LinkedIn contact link must be present',
          );
        },
      );

      test('Telegram entry: https://t.me/Abigotado', () {
        expect(
          urls,
          contains('https://t.me/Abigotado'),
          reason: 'Telegram contact link must be present (username, no number)',
        );
      });
    });

    // -----------------------------------------------------------------------
    // Non-empty guard — no label or url may be blank.
    // -----------------------------------------------------------------------
    group('non-empty fields', () {
      test('no label is empty', () {
        for (final link in contactLinks) {
          expect(
            link.label,
            isNotEmpty,
            reason: 'every contact link must have a non-empty label',
          );
        }
      });

      test('no url is empty', () {
        for (final link in contactLinks) {
          expect(
            link.url,
            isNotEmpty,
            reason: 'every contact link must have a non-empty url',
          );
        }
      });
    });
  });
}
