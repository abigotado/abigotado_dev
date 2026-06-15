import 'dart:ui';

import 'package:abigotado_dev/src/core/locale/locale_resolver.dart';
import 'package:abigotado_dev/src/core/locale/supported_locale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveLocale', () {
    group('stored preference (tier 1 — wins over everything)', () {
      test(
        'stored=ru, platform=[es-AR], tz=America/Mexico_City → ru',
        () {
          expect(
            resolveLocale(
              stored: SupportedLocale.ru,
              platformLocales: [const Locale('es', 'AR')],
              timeZoneId: 'America/Mexico_City',
            ),
            equals(SupportedLocale.ru),
          );
        },
      );

      test('stored=es, no platform, no tz → es', () {
        expect(
          resolveLocale(stored: SupportedLocale.es),
          equals(SupportedLocale.es),
        );
      });

      test('stored=en, no platform, no tz → en', () {
        expect(
          resolveLocale(stored: SupportedLocale.en),
          equals(SupportedLocale.en),
        );
      });
    });

    group('platform locales (tier 2 — first supported primary subtag)', () {
      test('[es-AR] → es', () {
        expect(
          resolveLocale(platformLocales: [const Locale('es', 'AR')]),
          equals(SupportedLocale.es),
        );
      });

      test('[es-419] → es (region subtag ignored)', () {
        expect(
          resolveLocale(platformLocales: [const Locale('es', '419')]),
          equals(SupportedLocale.es),
        );
      });

      test('[es-ES] → es (region subtag ignored)', () {
        expect(
          resolveLocale(platformLocales: [const Locale('es', 'ES')]),
          equals(SupportedLocale.es),
        );
      });

      test('[fr, ru] → ru (skip unsupported fr, match ru)', () {
        expect(
          resolveLocale(
            platformLocales: [const Locale('fr'), const Locale('ru')],
          ),
          equals(SupportedLocale.ru),
        );
      });

      test('[en] → en', () {
        expect(
          resolveLocale(platformLocales: [const Locale('en')]),
          equals(SupportedLocale.en),
        );
      });

      test(
        'platform [en] wins over tz America/Argentina/Cordoba → en',
        () {
          expect(
            resolveLocale(
              platformLocales: [const Locale('en')],
              timeZoneId: 'America/Argentina/Cordoba',
            ),
            equals(SupportedLocale.en),
          );
        },
      );
    });

    group(
      'timezone heuristic '
      '(tier 3 — only when stored null and no platform match)',
      () {
        test('platform=[fr], tz=Europe/Moscow → ru', () {
          expect(
            resolveLocale(
              platformLocales: [const Locale('fr')],
              timeZoneId: 'Europe/Moscow',
            ),
            equals(SupportedLocale.ru),
          );
        });

        test('tz=America/Mexico_City, no platform → es', () {
          expect(
            resolveLocale(timeZoneId: 'America/Mexico_City'),
            equals(SupportedLocale.es),
          );
        });
      },
    );

    group('en fallback (tier 4)', () {
      test('nothing provided → en', () {
        expect(resolveLocale(), equals(SupportedLocale.en));
      });

      test('only unsupported platform locales → en', () {
        expect(
          resolveLocale(
            platformLocales: [const Locale('fr'), const Locale('de')],
          ),
          equals(SupportedLocale.en),
        );
      });

      test('unknown tz America/New_York, no platform → en', () {
        expect(
          resolveLocale(timeZoneId: 'America/New_York'),
          equals(SupportedLocale.en),
        );
      });
    });
  });
}
