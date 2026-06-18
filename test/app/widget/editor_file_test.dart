import 'package:abigotado_dev/src/app/widget/editor_file.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helper: load AppLocalizations for a specific locale tag.
// ---------------------------------------------------------------------------

Future<AppLocalizations> _l10n(String languageCode) async {
  return AppLocalizations.delegate.load(Locale(languageCode));
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('EditorFile', () {
    group('values', () {
      test('enum values are in declaration order', () {
        expect(EditorFile.values, [
          EditorFile.fileHero,
          EditorFile.metrics,
          EditorFile.pubspec,
          EditorFile.changelog,
          EditorFile.contacts,
        ]);
      });
    });

    group('filename', () {
      test('fileHero filename is hero.dart', () {
        expect(EditorFile.fileHero.filename, equals('hero.dart'));
      });

      test('metrics filename is metrics.json', () {
        expect(EditorFile.metrics.filename, equals('metrics.json'));
      });

      test('pubspec filename is pubspec.yaml', () {
        expect(EditorFile.pubspec.filename, equals('pubspec.yaml'));
      });

      test('changelog filename is CHANGELOG.md', () {
        expect(EditorFile.changelog.filename, equals('CHANGELOG.md'));
      });

      test('contacts filename is contacts.dart', () {
        expect(EditorFile.contacts.filename, equals('contacts.dart'));
      });
    });

    group('icon', () {
      test('metrics icon is an IconData instance', () {
        expect(EditorFile.metrics.icon, isA<IconData>());
      });

      test('fileHero icon is an IconData instance', () {
        expect(EditorFile.fileHero.icon, isA<IconData>());
      });

      test('pubspec icon is an IconData instance', () {
        expect(EditorFile.pubspec.icon, isA<IconData>());
      });

      test('changelog icon is an IconData instance', () {
        expect(EditorFile.changelog.icon, isA<IconData>());
      });

      test('contacts icon is an IconData instance', () {
        expect(EditorFile.contacts.icon, isA<IconData>());
      });
    });

    group('label — en', () {
      late AppLocalizations l10n;

      setUp(() async {
        l10n = await _l10n('en');
      });

      test('fileHero label is "intro"', () {
        expect(EditorFile.fileHero.label(l10n), equals('intro'));
      });

      test('metrics label is "proof"', () {
        expect(EditorFile.metrics.label(l10n), equals('proof'));
      });

      test('pubspec label is "skills" (equals l10n.ch1)', () {
        expect(EditorFile.pubspec.label(l10n), equals('skills'));
        expect(EditorFile.pubspec.label(l10n), equals(l10n.ch1));
      });

      test('changelog label is "career" (equals l10n.ch2)', () {
        expect(EditorFile.changelog.label(l10n), equals('career'));
        expect(EditorFile.changelog.label(l10n), equals(l10n.ch2));
      });

      test('contacts label is "reach me"', () {
        expect(EditorFile.contacts.label(l10n), equals('reach me'));
      });
    });

    group('label — ru', () {
      late AppLocalizations l10n;

      setUp(() async {
        l10n = await _l10n('ru');
      });

      test('pubspec label is "навыки" (equals l10n.ch1)', () {
        expect(EditorFile.pubspec.label(l10n), equals('навыки'));
        expect(EditorFile.pubspec.label(l10n), equals(l10n.ch1));
      });

      test('changelog label is "карьера" (equals l10n.ch2)', () {
        expect(EditorFile.changelog.label(l10n), equals('карьера'));
        expect(EditorFile.changelog.label(l10n), equals(l10n.ch2));
      });
    });

    group('label — es', () {
      late AppLocalizations l10n;

      setUp(() async {
        l10n = await _l10n('es');
      });

      test('pubspec label is "habilidades" (equals l10n.ch1)', () {
        expect(EditorFile.pubspec.label(l10n), equals('habilidades'));
        expect(EditorFile.pubspec.label(l10n), equals(l10n.ch1));
      });

      test('changelog label is "carrera" (equals l10n.ch2)', () {
        expect(EditorFile.changelog.label(l10n), equals('carrera'));
        expect(EditorFile.changelog.label(l10n), equals(l10n.ch2));
      });
    });
  });
}
