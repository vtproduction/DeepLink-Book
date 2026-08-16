import 'package:deeplink_test_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app initially waits for a deeplink', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DeeplinkTestApp());

    expect(find.text('Waiting for deeplink'), findsWidgets);
  });

  testWidgets('test transfer button displays parsed deeplink details', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DeeplinkTestApp());

    await tester.tap(find.widgetWithText(OutlinedButton, 'Test Transfer'));
    await tester.pump();

    expect(
      find.text('deeplinktest://transfer?id=123&amount=500'),
      findsOneWidget,
    );
    expect(find.text('deeplinktest'), findsOneWidget);
    expect(find.text('transfer'), findsOneWidget);
    expect(find.text('id = 123'), findsOneWidget);
    expect(find.text('amount = 500'), findsOneWidget);
    expect(find.text('Transfer'), findsOneWidget);
  });

  testWidgets('test product button displays path and query values', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DeeplinkTestApp());

    await tester.tap(find.widgetWithText(OutlinedButton, 'Test Product'));
    await tester.pump();

    expect(
      find.text('deeplinktest://product/42?source=deeplink_book'),
      findsOneWidget,
    );
    expect(find.text('product'), findsOneWidget);
    expect(find.text('/42'), findsOneWidget);
    expect(find.text('productId = 42'), findsOneWidget);
    expect(find.text('source = deeplink_book'), findsOneWidget);
    expect(find.text('Product'), findsOneWidget);
  });
}
