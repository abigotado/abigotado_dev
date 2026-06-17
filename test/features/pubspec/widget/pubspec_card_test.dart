import 'package:abigotado_dev/src/app/theme/app_theme.dart';
import 'package:abigotado_dev/src/features/pubspec/content/pubspec_content.dart';
import 'package:abigotado_dev/src/features/pubspec/widget/pubspec_card.dart';
import 'package:abigotado_dev/src/features/pubspec/widget/pubspec_section.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helper: collect the plain text of every RichText in the tree, concatenated,
// so the body of a Text.rich / SelectableText.rich is searchable as a string.
// ---------------------------------------------------------------------------

String _collectRichText(WidgetTester tester) {
  final richTexts = tester.widgetList<RichText>(find.byType(RichText));
  return richTexts.map((rt) => (rt.text as TextSpan).toPlainText()).join('\n');
}

// ---------------------------------------------------------------------------
// Helper: pump PubspecSection (wraps PubspecCard) in a minimal Material/l10n
// tree at a fixed surface size.
// ---------------------------------------------------------------------------

Future<void> _pumpCard(
  WidgetTester tester, {
  required Size surface,
  Locale locale = const Locale('en'),
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: PubspecSection()),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('PubspecCard', () {
    // -----------------------------------------------------------------------
    // animation
    // -----------------------------------------------------------------------
    group('animation', () {
      testWidgets(
        'no transient callbacks after pumpAndSettle — section is static',
        (tester) async {
          await _pumpCard(tester, surface: const Size(800, 900));
          expect(
            tester.binding.transientCallbackCount,
            equals(0),
            reason:
                'PubspecCard has no animations; '
                'transient callbacks must be zero',
          );
        },
      );
    });

    // -----------------------------------------------------------------------
    // header
    // -----------------------------------------------------------------------
    group('header', () {
      testWidgets(
        'pubspec.yaml literal appears in the rendered card',
        (tester) async {
          await _pumpCard(tester, surface: const Size(800, 900));
          // The header Text('pubspec.yaml') and/or the a11y label both carry this.
          // findsAtLeastNWidgets(1) guards against zero occurrences.
          expect(
            find.textContaining('pubspec.yaml'),
            findsAtLeastNWidgets(1),
          );
        },
      );
    });

    // -----------------------------------------------------------------------
    // name value
    // -----------------------------------------------------------------------
    group('name value', () {
      testWidgets(
        'nikita_kovalenko appears in the rendered code body',
        (tester) async {
          await _pumpCard(tester, surface: const Size(800, 900));
          final body = _collectRichText(tester);
          expect(body, contains('nikita_kovalenko'));
        },
      );
    });

    // -----------------------------------------------------------------------
    // dependencies
    // -----------------------------------------------------------------------
    group('dependency lines', () {
      for (final dep in pubspecDependencies) {
        testWidgets(
          '${dep.package} package identifier renders',
          (tester) async {
            await _pumpCard(tester, surface: const Size(800, 900));
            final body = _collectRichText(tester);
            expect(
              body,
              contains(dep.package),
              reason:
                  'dependency "${dep.package}" must appear in the card body',
            );
          },
        );
      }

      testWidgets('^senior appears in the code body', (tester) async {
        await _pumpCard(tester, surface: const Size(800, 900));
        final body = _collectRichText(tester);
        expect(body, contains('^senior'));
      });

      testWidgets('^basic appears in the code body', (tester) async {
        await _pumpCard(tester, surface: const Size(800, 900));
        final body = _collectRichText(tester);
        expect(body, contains('^basic'));
      });
    });

    // -----------------------------------------------------------------------
    // languages + environment scaffolding
    // -----------------------------------------------------------------------
    group('scaffolding tokens', () {
      testWidgets('ru | en C2 | es C2 renders', (tester) async {
        await _pumpCard(tester, surface: const Size(800, 900));
        final body = _collectRichText(tester);
        expect(body, contains('ru | en C2 | es C2'));
      });

      testWidgets('"timezone" key renders', (tester) async {
        await _pumpCard(tester, surface: const Size(800, 900));
        final body = _collectRichText(tester);
        expect(body, contains('timezone'));
      });

      testWidgets('"flexible" value renders', (tester) async {
        await _pumpCard(tester, surface: const Size(800, 900));
        final body = _collectRichText(tester);
        expect(body, contains('flexible'));
      });

      testWidgets('"dependencies" section key renders', (tester) async {
        await _pumpCard(tester, surface: const Size(800, 900));
        final body = _collectRichText(tester);
        expect(body, contains('dependencies'));
      });

      testWidgets('"environment" section key renders', (tester) async {
        await _pumpCard(tester, surface: const Size(800, 900));
        final body = _collectRichText(tester);
        expect(body, contains('environment'));
      });
    });

    // -----------------------------------------------------------------------
    // i18n — en
    // -----------------------------------------------------------------------
    group('i18n — en', () {
      testWidgets('badge "skills" is present', (tester) async {
        await _pumpCard(
          tester,
          surface: const Size(800, 900),
        );
        expect(find.textContaining('skills'), findsAtLeastNWidgets(1));
      });

      testWidgets('kotlin_swift comment "# plugins, Pigeon" renders', (
        tester,
      ) async {
        await _pumpCard(tester, surface: const Size(800, 900));
        final body = _collectRichText(tester);
        expect(body, contains('# plugins, Pigeon'));
      });

      // -----------------------------------------------------------------------
      // description is GENERALIST guard (owner's hard positioning rule)
      // -----------------------------------------------------------------------
      testWidgets(
        'description contains "architecture" (generalist framing)',
        (tester) async {
          await _pumpCard(tester, surface: const Size(800, 900));
          final body = _collectRichText(tester);
          expect(
            body,
            contains('architecture'),
            reason:
                'pubspec description must include "architecture" — '
                'generalist framing',
          );
        },
      );

      testWidgets(
        'description contains "AI-first" (generalist framing)',
        (tester) async {
          await _pumpCard(tester, surface: const Size(800, 900));
          final body = _collectRichText(tester);
          expect(
            body,
            contains('AI-first'),
            reason:
                'pubspec description must include "AI-first" — '
                'generalist framing',
          );
        },
      );

      testWidgets(
        'description does NOT contain "fintech" (guards against '
        'fintech-as-headline regression)',
        (tester) async {
          await _pumpCard(tester, surface: const Size(800, 900));
          final body = _collectRichText(tester);
          expect(
            body.toLowerCase(),
            isNot(contains('fintech')),
            reason:
                'pubspec description must NOT mention fintech — '
                'owner positioning rule: generalist, not fintech',
          );
        },
      );
    });

    // -----------------------------------------------------------------------
    // i18n — ru
    // -----------------------------------------------------------------------
    group('i18n — ru', () {
      testWidgets('badge "навыки" is present', (tester) async {
        await _pumpCard(
          tester,
          surface: const Size(800, 900),
          locale: const Locale('ru'),
        );
        expect(find.textContaining('навыки'), findsAtLeastNWidgets(1));
      });

      testWidgets('kotlin_swift comment "# плагины, Pigeon" renders', (
        tester,
      ) async {
        await _pumpCard(
          tester,
          surface: const Size(800, 900),
          locale: const Locale('ru'),
        );
        final body = _collectRichText(tester);
        expect(body, contains('# плагины, Pigeon'));
      });

      testWidgets('English badge "skills" is absent under ru locale', (
        tester,
      ) async {
        await _pumpCard(
          tester,
          surface: const Size(800, 900),
          locale: const Locale('ru'),
        );
        // find.text does exact matching on RichText nodes; the badge is a
        // standalone Text widget so find.text('skills') must find nothing.
        expect(find.text('skills'), findsNothing);
      });
    });

    // -----------------------------------------------------------------------
    // i18n — es
    // -----------------------------------------------------------------------
    group('i18n — es', () {
      testWidgets('badge "habilidades" is present', (tester) async {
        await _pumpCard(
          tester,
          surface: const Size(800, 900),
          locale: const Locale('es'),
        );
        expect(find.textContaining('habilidades'), findsAtLeastNWidgets(1));
      });
    });

    // -----------------------------------------------------------------------
    // a11y
    // -----------------------------------------------------------------------
    group('a11y', () {
      testWidgets(
        'outermost Semantics node label is the localized summary followed by '
        'the skill names, with decorative version tokens excluded',
        (tester) async {
          final handle = tester.ensureSemantics();

          await _pumpCard(
            tester,
            surface: const Size(800, 900),
          );

          // The outermost Semantics on PubspecCard wraps the whole card with
          // the a11y label and ExcludeSemantics hides the code tokens inside.
          final node = tester.getSemantics(find.byType(PubspecCard));

          expect(
            node.label,
            contains('skills, pubspec.yaml'),
            reason:
                'screen-reader label must contain the localized a11y string',
          );

          // The skills are the section's CONTENT, not decoration: they must be
          // announced. The label enumerates them (generated from the content
          // list), with known acronyms humanized (ai → AI, ddd → DDD).
          expect(
            node.label,
            contains('team leadership'),
            reason: 'a skill name must be announced, not just the summary',
          );
          expect(
            node.label,
            contains('AI first pipelines'),
            reason: 'acronym AI must be humanized in the spoken skill list',
          );
          expect(
            node.label,
            contains('architecture DDD'),
            reason: 'acronym DDD must be humanized in the spoken skill list',
          );

          // Decorative code tokens (version constraints) stay out of the tree:
          // the aggregated label must NOT contain version syntax.
          expect(
            node.label,
            isNot(contains('^evangelist')),
            reason: 'decorative version tokens must be excluded from a11y',
          );

          handle.dispose();
        },
      );
    });

    // -----------------------------------------------------------------------
    // 320 px — no horizontal overflow
    // -----------------------------------------------------------------------
    group('narrow layout', () {
      testWidgets(
        '320 px wide — no exception, card is present '
        '(SingleChildScrollView prevents overflow)',
        (tester) async {
          await _pumpCard(
            tester,
            surface: const Size(320, 900),
          );

          // No layout exception (RenderFlex overflow etc.)
          expect(tester.takeException(), isNull);

          // The card widget itself must be present in the tree.
          expect(find.byType(PubspecCard), findsOneWidget);
        },
      );
    });
  });
}
