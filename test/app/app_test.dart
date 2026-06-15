import 'package:abigotado_dev/src/app/app.dart';
import 'package:abigotado_dev/src/app/view/landing_page.dart';
import 'package:abigotado_dev/src/core/locale/locale_store.dart';
import 'package:abigotado_dev/src/core/locale/supported_locale.dart';
import 'package:abigotado_dev/src/features/locale/state/locale_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal fake [LocaleStore] that satisfies the compile requirement.
/// Logic is stubbed — the [test-writer] will replace this in the GREEN phase.
final class _FakeLocaleStore implements LocaleStore {
  @override
  SupportedLocale? read() => throw UnimplementedError();

  @override
  Future<void> write(SupportedLocale locale) => throw UnimplementedError();

  @override
  Future<void> clear() => throw UnimplementedError();
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AbigotadoApp', () {
    testWidgets('renders the landing page without a debug banner', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeStoreProvider.overrideWithValue(_FakeLocaleStore()),
          ],
          child: const AbigotadoApp(),
        ),
      );

      expect(find.byType(LandingPage), findsOneWidget);

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.debugShowCheckedModeBanner, isFalse);
    });

    testWidgets('shows the name on the landing page', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeStoreProvider.overrideWithValue(_FakeLocaleStore()),
          ],
          child: const AbigotadoApp(),
        ),
      );

      expect(find.text('Nikita Kovalenko'), findsOneWidget);
    });
  });
}
