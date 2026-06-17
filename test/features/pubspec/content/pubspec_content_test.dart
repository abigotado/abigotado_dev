import 'package:abigotado_dev/src/features/pubspec/content/pubspec_content.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Pure content guard tests — no widgets, no BuildContext, no mocks.
// These test the owner's hard positioning rules against the real list.
// They PASS from birth (regression guards) — a future content edit that
// violates a rule will break one of these tests, not the widget tests.
// ---------------------------------------------------------------------------

void main() {
  group('pubspecDependencies', () {
    group('kotlin_swift version', () {
      test('^basic — kotlin_swift pins ^basic (never overclaim native)', () {
        final dep = pubspecDependencies.firstWhere(
          (d) => d.package == 'kotlin_swift',
        );
        expect(dep.version, equals('^basic'));
      });
    });

    group('no Python mentions', () {
      test(
        'no package or version contains "python" (owner rule: Python never '
        'mentioned)',
        () {
          for (final dep in pubspecDependencies) {
            expect(
              dep.package.toLowerCase(),
              isNot(contains('python')),
              reason: 'package "${dep.package}" must not mention Python',
            );
            expect(
              dep.version.toLowerCase(),
              isNot(contains('python')),
              reason:
                  'version "${dep.version}" on ${dep.package} must not mention '
                  'Python',
            );
          }
        },
      );
    });

    group('localized comment ownership', () {
      test(
        'only the kotlin_swift entry carries a localized comment — '
        'guards the single-comment render template assumption',
        () {
          final withComment = pubspecDependencies
              .where((d) => d.comment != null)
              .map((d) => d.package)
              .toList();

          expect(withComment, equals(['kotlin_swift']));
        },
      );
    });

    group('structural integrity', () {
      // Uniqueness: a duplicate package identifier would render two identical
      // code lines, silently misleading the reader.  The list is short and
      // hand-maintained — a real accidental dup is plausible.
      test('package identifiers are unique', () {
        final packages = pubspecDependencies.map((d) => d.package).toList();
        final unique = packages.toSet();
        expect(
          packages.length,
          equals(unique.length),
          reason: () {
            final dups = packages
                .where(
                  (p) => packages.where((q) => q == p).length > 1,
                )
                .toSet();
            return 'duplicate package identifier(s) found: $dups';
          }(),
        );
      });
    });
  });
}
