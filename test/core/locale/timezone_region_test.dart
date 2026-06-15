import 'package:abigotado_dev/src/core/locale/supported_locale.dart';
import 'package:abigotado_dev/src/core/locale/timezone_region.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('localeForTimeZone', () {
    group('Russian timezones', () {
      test('Europe/Moscow → ru', () {
        expect(localeForTimeZone('Europe/Moscow'), equals(SupportedLocale.ru));
      });

      test('Asia/Yekaterinburg → ru', () {
        expect(
          localeForTimeZone('Asia/Yekaterinburg'),
          equals(SupportedLocale.ru),
        );
      });
    });

    group('Spanish timezones', () {
      test('America/Mexico_City → es', () {
        expect(
          localeForTimeZone('America/Mexico_City'),
          equals(SupportedLocale.es),
        );
      });

      test('America/Argentina/Buenos_Aires → es', () {
        expect(
          localeForTimeZone('America/Argentina/Buenos_Aires'),
          equals(SupportedLocale.es),
        );
      });

      test('America/Argentina/Cordoba → es', () {
        expect(
          localeForTimeZone('America/Argentina/Cordoba'),
          equals(SupportedLocale.es),
        );
      });
    });

    group('unmapped or ambiguous timezones', () {
      test('null → null', () {
        expect(localeForTimeZone(null), isNull);
      });

      test('empty string → null', () {
        expect(localeForTimeZone(''), isNull);
      });

      test('America/New_York → null', () {
        expect(localeForTimeZone('America/New_York'), isNull);
      });

      test('Europe/Madrid → null', () {
        expect(localeForTimeZone('Europe/Madrid'), isNull);
      });

      test('unknown timezone → null', () {
        expect(localeForTimeZone('Oceania/Unknown'), isNull);
      });
    });
  });
}
