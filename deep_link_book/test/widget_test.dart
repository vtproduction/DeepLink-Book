import 'package:deep_link_book/app/app.dart';
import 'package:deep_link_book/app/router.dart';
import 'package:deep_link_book/app/theme/app_theme.dart';
import 'package:deep_link_book/core/database/app_database.dart';
import 'package:deep_link_book/core/widgets/app_confirm_dialog.dart';
import 'package:deep_link_book/core/widgets/app_empty_state.dart';
import 'package:deep_link_book/features/deeplinks/providers/deeplink_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('shows the Home loading state', (WidgetTester tester) async {
    await pumpApp(tester, deeplinksValue: const AsyncLoading());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows the Home empty state', (WidgetTester tester) async {
    await pumpApp(tester, deeplinks: const []);

    expect(find.text('No deeplinks yet'), findsOneWidget);
    expect(
      find.text('Create your first deeplink to get started.'),
      findsOneWidget,
    );
  });

  testWidgets('supports light and dark themes', (WidgetTester tester) async {
    await pumpApp(tester, deeplinks: const []);

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(materialApp.theme, AppTheme.lightTheme);
    expect(materialApp.darkTheme, AppTheme.darkTheme);
    expect(materialApp.themeMode, ThemeMode.system);
  });

  testWidgets('shows the bottom navigation tabs', (WidgetTester tester) async {
    await pumpApp(tester, deeplinks: const []);

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
    await pumpApp(tester, deeplinks: const []);

    await tester.tap(find.widgetWithText(NavigationDestination, 'History'));
    await tester.pumpAndSettle();

    expect(find.text('History screen placeholder'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('navigates from Home to Settings', (WidgetTester tester) async {
    await pumpApp(tester, deeplinks: const []);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Settings screen placeholder'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('shows deeplink data on Home', (WidgetTester tester) async {
    await pumpApp(
      tester,
      deeplinks: [
        testDeeplink(
          id: 1,
          name: 'Transfer Out',
          url: 'ascendbank-qa://transfer_out',
        ),
        testDeeplink(id: 2, name: 'Profile', url: 'ascendbank-qa://profile'),
      ],
    );

    expect(find.text('Transfer Out'), findsOneWidget);
    expect(find.text('ascendbank-qa://transfer_out'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('ascendbank-qa://profile'), findsOneWidget);
  });

  testWidgets('shows favorite indicator and open count', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      deeplinks: [
        testDeeplink(
          id: 1,
          name: 'Transfer Out',
          url: 'ascendbank-qa://transfer_out',
          isFavorite: true,
          openCount: 3,
        ),
      ],
    );

    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.text('Opened 3 times'), findsOneWidget);
  });

  testWidgets('handles long deeplink URLs without overflow', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      deeplinks: [
        testDeeplink(
          id: 1,
          name: 'Very Long URL',
          url:
              'ascendbank-qa://transfer_out/with/a/very/long/path/that/keeps/going?account=primary&amount=1000&note=this-is-a-long-note',
        ),
      ],
    );

    expect(find.text('Very Long URL'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows Home error state', (WidgetTester tester) async {
    await pumpApp(
      tester,
      deeplinksValue: AsyncValue.error(
        Exception('Database failed'),
        StackTrace.empty,
      ),
    );

    expect(find.text('Unable to load deeplinks'), findsOneWidget);
    expect(find.text('Please try again later.'), findsOneWidget);
  });

  testWidgets('opens Add Deeplink from the Home FAB', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, deeplinks: const []);

    await tester.tap(find.byTooltip('Add Deeplink'));
    await tester.pumpAndSettle();

    expect(find.text('Add Deeplink'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Deeplink URL'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('returns from Add Deeplink to Home with back', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, deeplinks: const []);

    await tester.tap(find.byTooltip('Add Deeplink'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('No deeplinks yet'), findsOneWidget);
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

Future<void> pumpApp(
  WidgetTester tester, {
  List<Deeplink>? deeplinks,
  AsyncValue<List<Deeplink>>? deeplinksValue,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        deeplinksProvider.overrideWithValue(
          deeplinksValue ?? AsyncValue.data(deeplinks ?? const []),
        ),
      ],
      child: App(router: createAppRouter()),
    ),
  );
}

Deeplink testDeeplink({
  required int id,
  required String name,
  required String url,
  bool isFavorite = false,
  int openCount = 0,
}) {
  final now = DateTime(2026, 8, 13, 10);

  return Deeplink(
    id: id,
    name: name,
    url: url,
    isFavorite: isFavorite,
    openCount: openCount,
    createdAt: now,
    updatedAt: now,
  );
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
