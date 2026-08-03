import 'package:deep_link_book/app/app.dart';
import 'package:deep_link_book/app/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('shows the initial home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(child: App(router: createAppRouter())),
    );

    expect(find.text('Deeplink Manager home'), findsOneWidget);
  });

  testWidgets('shows the bottom navigation tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(child: App(router: createAppRouter())),
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.widgetWithText(NavigationDestination, 'Home'), findsOneWidget);
    expect(
      find.widgetWithText(NavigationDestination, 'History'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(NavigationDestination, 'Settings'),
      findsOneWidget,
    );
  });

  testWidgets('navigates from Home to History', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(child: App(router: createAppRouter())),
    );

    await tester.tap(find.widgetWithText(NavigationDestination, 'History'));
    await tester.pumpAndSettle();

    expect(find.text('History screen placeholder'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('navigates from Home to Settings', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(child: App(router: createAppRouter())),
    );

    await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Settings screen placeholder'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('opens Add Deeplink from the Home FAB', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(child: App(router: createAppRouter())),
    );

    await tester.tap(find.byTooltip('Add Deeplink'));
    await tester.pumpAndSettle();

    expect(find.text('Add Deeplink'), findsOneWidget);
    expect(find.text('Add deeplink screen placeholder'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('returns from Add Deeplink to Home with back', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(child: App(router: createAppRouter())),
    );

    await tester.tap(find.byTooltip('Add Deeplink'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Deeplink Manager home'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
