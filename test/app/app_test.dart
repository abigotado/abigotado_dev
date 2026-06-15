import 'package:abigotado_dev/src/app/app.dart';
import 'package:abigotado_dev/src/app/view/landing_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AbigotadoApp', () {
    testWidgets('renders the landing page without a debug banner', (
      tester,
    ) async {
      await tester.pumpWidget(const AbigotadoApp());

      expect(find.byType(LandingPage), findsOneWidget);

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.debugShowCheckedModeBanner, isFalse);
    });

    testWidgets('shows the name on the landing page', (tester) async {
      await tester.pumpWidget(const AbigotadoApp());

      expect(find.text('Nikita Kovalenko'), findsOneWidget);
    });
  });
}
