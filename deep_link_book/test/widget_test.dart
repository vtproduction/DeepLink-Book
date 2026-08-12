import 'package:deep_link_book/app/app.dart';
import 'package:deep_link_book/app/router.dart';
import 'package:deep_link_book/app/theme/app_theme.dart';
import 'package:deep_link_book/core/widgets/app_confirm_dialog.dart';
import 'package:deep_link_book/core/widgets/app_empty_state.dart';
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

  testWidgets('supports light and dark themes', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(child: App(router: createAppRouter())),
    );

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(materialApp.theme, AppTheme.lightTheme);
    expect(materialApp.darkTheme, AppTheme.darkTheme);
    expect(materialApp.themeMode, ThemeMode.system);
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

  testWidgets('AppEmptyState renders optional content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: AppEmptyState(
            icon: Icons.link_off,
            title: 'No deeplinks yet',
            description: 'Saved deeplinks will appear here.',
            action: FilledButton(
              onPressed: () {},
              child: const Text('Add one'),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.link_off), findsOneWidget);
    expect(find.text('No deeplinks yet'), findsOneWidget);
    expect(find.text('Saved deeplinks will appear here.'), findsOneWidget);
    expect(find.text('Add one'), findsOneWidget);
  });

  testWidgets('confirmation dialog returns true when confirmed', (
    WidgetTester tester,
  ) async {
    bool? result;

    await tester.pumpWidget(
      _ConfirmDialogTestApp(
        onResult: (value) {
          result = value;
        },
      ),
    );

    await tester.tap(find.text('Show dialog'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('confirmation dialog returns false when cancelled', (
    WidgetTester tester,
  ) async {
    bool? result;

    await tester.pumpWidget(
      _ConfirmDialogTestApp(
        onResult: (value) {
          result = value;
        },
      ),
    );

    await tester.tap(find.text('Show dialog'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets('confirmation dialog returns false when dismissed', (
    WidgetTester tester,
  ) async {
    bool? result;

    await tester.pumpWidget(
      _ConfirmDialogTestApp(
        onResult: (value) {
          result = value;
        },
      ),
    );

    await tester.tap(find.text('Show dialog'));
    await tester.pumpAndSettle();
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });
}

class _ConfirmDialogTestApp extends StatelessWidget {
  const _ConfirmDialogTestApp({required this.onResult});

  final ValueChanged<bool> onResult;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  final result = await showAppConfirmDialog(
                    context: context,
                    title: 'Delete item?',
                    message: 'This action needs confirmation.',
                  );

                  onResult(result);
                },
                child: const Text('Show dialog'),
              ),
            ),
          );
        },
      ),
    );
  }
}
