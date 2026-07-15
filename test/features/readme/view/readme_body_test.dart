import 'package:abigotado_dev/src/app/theme/app_theme.dart';
import 'package:abigotado_dev/src/app/widget/contact_link_tile.dart';
import 'package:abigotado_dev/src/core/effects/effects_mode.dart';
import 'package:abigotado_dev/src/core/effects/effects_store.dart';
import 'package:abigotado_dev/src/features/effects/state/effects_notifier.dart';
import 'package:abigotado_dev/src/features/readme/content/experience_content.dart';
import 'package:abigotado_dev/src/features/readme/view/readme_body.dart';
import 'package:abigotado_dev/src/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake — lite effects, mirrors _LiteEffectsStore across the suite.
// ---------------------------------------------------------------------------

final class _LiteEffectsStore implements EffectsStore {
  const _LiteEffectsStore();

  @override
  EffectsMode? read() => EffectsMode.lite;

  @override
  Future<void> write(EffectsMode mode) async {}

  @override
  Future<void> clear() async {}
}

// ---------------------------------------------------------------------------
// Helper: collect the plain text of every RichText in the tree (mirrors
// changelog_card_test.dart's _collectRichText).
// ---------------------------------------------------------------------------

String _collectRichText(WidgetTester tester) {
  final richTexts = tester.widgetList<RichText>(find.byType(RichText));
  return richTexts.map((rt) => (rt.text as TextSpan).toPlainText()).join('\n');
}

// ---------------------------------------------------------------------------
// Helper: pump the full ReadmeBody (one key per ReadmeAnchor) inside a
// ProviderScope(lite) + MaterialApp(l10n, dark theme) + SingleChildScrollView
// (the body is a pure column, so a scroll view lets it lay out at intrinsic
// height without overflow, mirroring pumpGoldenSection).
// ---------------------------------------------------------------------------

Future<void> _pumpBody(
  WidgetTester tester, {
  required Size surface,
  Locale locale = const Locale('en'),
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        effectsStoreProvider.overrideWithValue(const _LiteEffectsStore()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReadmeBody(
              sectionKeys: {
                for (final a in ReadmeAnchor.values) a: GlobalKey(),
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpHeaderCrop(
  WidgetTester tester, {
  required Size surface,
  Locale locale = const Locale('en'),
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        effectsStoreProvider.overrideWithValue(const _LiteEffectsStore()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(child: ReadmeBody.headerCrop()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ReadmeBody', () {
    // -------------------------------------------------------------------------
    group('header + collaboration', () {
      testWidgets('l10n.name and l10n.rm_role render', (tester) async {
        await _pumpBody(tester, surface: const Size(1000, 3000));
        final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));

        expect(find.text(l10n.name), findsOneWidget);
        expect(find.text(l10n.rm_role), findsOneWidget);
      });

      testWidgets(
        'rm_collab_intro and the 3 collaboration items render',
        (tester) async {
          await _pumpBody(tester, surface: const Size(1000, 3000));
          final l10n = AppLocalizations.of(
            tester.element(find.byType(Scaffold)),
          );

          expect(find.text(l10n.rm_collab_intro), findsOneWidget);
          expect(find.text(l10n.rm_collab_staff), findsOneWidget);
          expect(find.text(l10n.rm_collab_contract), findsOneWidget);
          expect(find.text(l10n.rm_collab_team), findsOneWidget);
        },
      );
    });

    // -------------------------------------------------------------------------
    group('about / AI / domains', () {
      testWidgets('rm_about, rm_ai, rm_domains present', (tester) async {
        await _pumpBody(tester, surface: const Size(1000, 3000));
        final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));

        expect(find.text(l10n.rm_about), findsOneWidget);
        expect(find.text(l10n.rm_ai), findsOneWidget);
        expect(find.text(l10n.rm_domains), findsOneWidget);
      });
    });

    // -------------------------------------------------------------------------
    group('experience', () {
      testWidgets('all 6 org strings render', (tester) async {
        await _pumpBody(tester, surface: const Size(1000, 5000));
        final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));

        for (final entry in experienceEntries) {
          expect(
            find.text(entry.org(l10n)),
            findsOneWidget,
            reason: 'org "${entry.org(l10n)}" must render exactly once',
          );
        }
      });

      testWidgets('per-org achievement bullets render', (tester) async {
        await _pumpBody(tester, surface: const Size(1000, 5000));
        final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));
        final body = _collectRichText(tester);

        for (final entry in experienceEntries) {
          for (final achievement in entry.achievements) {
            expect(
              body,
              contains(achievement(l10n)),
              reason:
                  'achievement "${achievement(l10n)}" for org '
                  '"${entry.org(l10n)}" must appear in the rendered body',
            );
          }
        }
      });

      testWidgets(
        'orgs render as plain text — no link semantics over an org row '
        '(url is null in stage 1)',
        (tester) async {
          final handle = tester.ensureSemantics();
          await _pumpBody(tester, surface: const Size(1000, 5000));
          final l10n = AppLocalizations.of(
            tester.element(find.byType(Scaffold)),
          );

          // Take the first org — a link Semantics ancestor over its Text
          // would mean stage 1 rendered a link despite entry.url == null.
          final firstOrg = experienceEntries.first.org(l10n);
          final orgFinder = find.text(firstOrg);
          expect(orgFinder, findsOneWidget);

          final node = tester.getSemantics(orgFinder);
          final data = node.getSemanticsData();
          expect(
            data.flagsCollection.isLink,
            isFalse,
            reason:
                'org "$firstOrg" has url == null in stage 1 — it must not '
                'expose the isLink semantic flag',
          );

          handle.dispose();
        },
      );

      testWidgets(
        'no ExcludeSemantics ancestor over the experience prose',
        (tester) async {
          final handle = tester.ensureSemantics();
          await _pumpBody(tester, surface: const Size(1000, 5000));
          final l10n = AppLocalizations.of(
            tester.element(find.byType(Scaffold)),
          );

          final firstOrg = experienceEntries.first.org(l10n);
          expect(
            find.ancestor(
              of: find.text(firstOrg),
              matching: find.byType(ExcludeSemantics),
            ),
            findsNothing,
            reason:
                'experience prose must be readable by assistive tech — no '
                'ExcludeSemantics ancestor over an org row',
          );

          handle.dispose();
        },
      );
    });

    // -------------------------------------------------------------------------
    group('education / certifications / languages', () {
      testWidgets(
        'education titles (×2) and certification lines (×2) render',
        (tester) async {
          await _pumpBody(tester, surface: const Size(1000, 5000));
          final l10n = AppLocalizations.of(
            tester.element(find.byType(Scaffold)),
          );

          expect(find.text(l10n.rm_edu1_t), findsOneWidget);
          expect(find.text(l10n.rm_edu2_t), findsOneWidget);
          expect(find.text(l10n.rm_cert1), findsOneWidget);
          expect(find.text(l10n.rm_cert2), findsOneWidget);
        },
      );

      testWidgets('rm_languages renders', (tester) async {
        await _pumpBody(tester, surface: const Size(1000, 5000));
        final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));

        expect(find.text(l10n.rm_languages), findsOneWidget);
      });
    });

    // -------------------------------------------------------------------------
    group('contacts', () {
      testWidgets('exactly 5 ContactLinkTile widgets render', (tester) async {
        await _pumpBody(tester, surface: const Size(1000, 5000));

        expect(find.byType(ContactLinkTile), findsNWidgets(5));
      });
    });

    // -------------------------------------------------------------------------
    group('locale sanity', () {
      testWidgets('ru: name and rm_role render', (tester) async {
        await _pumpBody(
          tester,
          surface: const Size(1000, 3000),
          locale: const Locale('ru'),
        );
        final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));

        expect(find.text(l10n.name), findsOneWidget);
        expect(find.text(l10n.rm_role), findsOneWidget);
      });

      testWidgets('es: name and rm_role render', (tester) async {
        await _pumpBody(
          tester,
          surface: const Size(1000, 3000),
          locale: const Locale('es'),
        );
        final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));

        expect(find.text(l10n.name), findsOneWidget);
        expect(find.text(l10n.rm_role), findsOneWidget);
      });
    });

    // -------------------------------------------------------------------------
    group('headerCrop', () {
      testWidgets(
        'renders name/rm_role/rm_collab_intro/rm_about but no org string '
        'and no ContactLinkTile',
        (tester) async {
          await _pumpHeaderCrop(tester, surface: const Size(1000, 1200));
          final l10n = AppLocalizations.of(
            tester.element(find.byType(Scaffold)),
          );

          expect(find.text(l10n.name), findsOneWidget);
          expect(find.text(l10n.rm_role), findsOneWidget);
          expect(find.text(l10n.rm_collab_intro), findsOneWidget);
          expect(find.text(l10n.rm_about), findsOneWidget);

          for (final entry in experienceEntries) {
            expect(
              find.text(entry.org(l10n)),
              findsNothing,
              reason:
                  'headerCrop must not render experience — org '
                  '"${entry.org(l10n)}" must be absent',
            );
          }
          expect(find.byType(ContactLinkTile), findsNothing);
        },
      );

      testWidgets(
        '320×tall es surface — no exception (vacuous-green on stub, '
        'stays as a guard)',
        (tester) async {
          await _pumpHeaderCrop(
            tester,
            surface: const Size(320, 1600),
            locale: const Locale('es'),
          );

          expect(tester.takeException(), isNull);
        },
      );
    });
  });
}
