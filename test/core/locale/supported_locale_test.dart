import 'dart:ui';

import 'package:abigotado_dev/src/core/locale/supported_locale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SupportedLocale', () {
    group('toLocale', () {
      test('ru → Locale(ru)', () {
        expect(SupportedLocale.ru.toLocale(), equals(const Locale('ru')));
      });

      test('en → Locale(en)', () {
        expect(SupportedLocale.en.toLocale(), equals(const Locale('en')));
      });

      test('es → Locale(es)', () {
        expect(SupportedLocale.es.toLocale(), equals(const Locale('es')));
      });
    });

    group('label', () {
      test('ru → RU', () {
        expect(SupportedLocale.ru.label, equals('RU'));
      });

      test('en → EN', () {
        expect(SupportedLocale.en.label, equals('EN'));
      });

      test('es → ES', () {
        expect(SupportedLocale.es.label, equals('ES'));
      });
    });

    group('fromCode', () {
      test('ru → SupportedLocale.ru', () {
        expect(SupportedLocale.fromCode('ru'), equals(SupportedLocale.ru));
      });

      test('en → SupportedLocale.en', () {
        expect(SupportedLocale.fromCode('en'), equals(SupportedLocale.en));
      });

      test('es → SupportedLocale.es', () {
        expect(SupportedLocale.fromCode('es'), equals(SupportedLocale.es));
      });

      test('RU (uppercase) → SupportedLocale.ru', () {
        expect(SupportedLocale.fromCode('RU'), equals(SupportedLocale.ru));
      });

      test('EN (uppercase) → SupportedLocale.en', () {
        expect(SupportedLocale.fromCode('EN'), equals(SupportedLocale.en));
      });

      test('ES (uppercase) → SupportedLocale.es', () {
        expect(SupportedLocale.fromCode('ES'), equals(SupportedLocale.es));
      });

      test('null → null', () {
        expect(SupportedLocale.fromCode(null), isNull);
      });

      test('empty string → null', () {
        expect(SupportedLocale.fromCode(''), isNull);
      });

      test('fr (unsupported) → null', () {
        expect(SupportedLocale.fromCode('fr'), isNull);
      });
    });
  });
}
