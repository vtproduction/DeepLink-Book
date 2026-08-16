import 'package:deep_link_book/app/theme/app_theme.dart';
import 'package:deep_link_book/core/database/app_database.dart';
import 'package:deep_link_book/core/database/database_provider.dart';
import 'package:deep_link_book/features/history/data/history_repository.dart';
import 'package:deep_link_book/features/history/providers/history_providers.dart';
import 'package:deep_link_book/features/history/screens/history_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the loading state', (WidgetTester tester) async {
    await pumpHistoryScreen(
      tester,
      historyValue: const AsyncLoading<List<DeeplinkHistory>>(),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows the empty state', (WidgetTester tester) async {
    await pumpHistoryScreen(tester, history: const []);

    expect(find.text('No history yet'), findsOneWidget);
    expect(find.text('Opened deeplinks will appear here.'), findsOneWidget);
  });

  testWidgets('shows a successful history item', (WidgetTester tester) async {
    await pumpHistoryScreen(
      tester,
      history: [
        testHistory(
          id: 1,
          name: 'Transfer Out',
          url: 'deeplinktest://transfer?id=123',
          isSuccess: true,
        ),
      ],
    );

    expect(find.text('Transfer Out'), findsOneWidget);
    expect(find.text('deeplinktest://transfer?id=123'), findsOneWidget);
    expect(find.text('Success'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('shows a failed history item with its safe error', (
    WidgetTester tester,
  ) async {
    await pumpHistoryScreen(
      tester,
      history: [
        testHistory(
          id: 1,
          name: 'Profile',
          url: 'deeplinktest://profile',
          isSuccess: false,
          errorMessage: 'No app can open this deeplink.',
        ),
      ],
    );

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.byIcon(Icons.error), findsOneWidget);
    expect(find.text('No app can open this deeplink.'), findsOneWidget);
  });

  testWidgets('does not show an error message for successful history', (
    WidgetTester tester,
  ) async {
    await pumpHistoryScreen(
      tester,
      history: [
        testHistory(
          id: 1,
          name: 'Transfer Out',
          url: 'deeplinktest://transfer?id=123',
          isSuccess: true,
        ),
      ],
    );

    expect(find.text('Success'), findsOneWidget);
    expect(find.text('No app can open this deeplink.'), findsNothing);
  });

  testWidgets('shows multiple history rows', (WidgetTester tester) async {
    await pumpHistoryScreen(
      tester,
      history: [
        testHistory(id: 1, name: 'Transfer', url: 'deeplinktest://transfer'),
        testHistory(id: 2, name: 'Profile', url: 'deeplinktest://profile'),
      ],
    );

    expect(find.text('Transfer'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('renders rows in the provided newest-first order', (
    WidgetTester tester,
  ) async {
    await pumpHistoryScreen(
      tester,
      history: [
        testHistory(
          id: 2,
          name: 'Newest',
          url: 'deeplinktest://newest',
          openedAt: DateTime(2026, 8, 17, 12),
        ),
        testHistory(
          id: 1,
          name: 'Oldest',
          url: 'deeplinktest://oldest',
          openedAt: DateTime(2026, 8, 17, 10),
        ),
      ],
    );

    final newestTop = tester.getTopLeft(find.text('Newest')).dy;
    final oldestTop = tester.getTopLeft(find.text('Oldest')).dy;

    expect(newestTop, lessThan(oldestTop));
  });

  testWidgets('handles long history URLs without overflow', (
    WidgetTester tester,
  ) async {
    await pumpHistoryScreen(
      tester,
      history: [
        testHistory(
          id: 1,
          name: 'Long URL',
          url:
              'deeplinktest://transfer/with/a/very/long/path/that/keeps/going?account=primary&amount=1000&source=deeplink_book&note=this-is-a-long-note',
        ),
      ],
    );

    expect(find.text('Long URL'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders a history row with nullable deeplink id', (
    WidgetTester tester,
  ) async {
    await pumpHistoryScreen(
      tester,
      history: [
        testHistory(
          id: 1,
          deeplinkId: null,
          name: 'Quick Open',
          url: 'deeplinktest://profile',
        ),
      ],
    );

    expect(find.text('Quick Open'), findsOneWidget);
    expect(find.text('deeplinktest://profile'), findsOneWidget);
  });

  testWidgets('shows the error state', (WidgetTester tester) async {
    await pumpHistoryScreen(
      tester,
      historyValue: AsyncError<List<DeeplinkHistory>>(
        Exception('Database failed'),
        StackTrace.empty,
      ),
    );

    expect(find.text('Unable to load history.'), findsOneWidget);
    expect(find.text('Please try again later.'), findsOneWidget);
  });

  testWidgets('updates automatically when history is inserted', (
    WidgetTester tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = HistoryRepository(database);
    addTearDown(database.close);

    await pumpHistoryScreen(tester, database: database);
    await tester.pumpAndSettle();

    expect(find.text('No history yet'), findsOneWidget);

    await repository.createHistory(
      name: 'Transfer Out',
      url: 'deeplinktest://transfer?id=123',
      isSuccess: true,
    );
    await tester.pumpAndSettle();

    expect(find.text('Transfer Out'), findsOneWidget);
    expect(find.text('deeplinktest://transfer?id=123'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}

Future<void> pumpHistoryScreen(
  WidgetTester tester, {
  AppDatabase? database,
  List<DeeplinkHistory>? history,
  AsyncValue<List<DeeplinkHistory>>? historyValue,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (database != null) appDatabaseProvider.overrideWithValue(database),
        if (database == null)
          historyProvider.overrideWithValue(
            historyValue ?? AsyncValue.data(history ?? const []),
          ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const HistoryScreen(),
      ),
    ),
  );
}

DeeplinkHistory testHistory({
  required int id,
  int? deeplinkId = 1,
  required String name,
  required String url,
  bool isSuccess = true,
  String? errorMessage,
  DateTime? openedAt,
}) {
  return DeeplinkHistory(
    id: id,
    deeplinkId: deeplinkId,
    name: name,
    url: url,
    isSuccess: isSuccess,
    errorMessage: errorMessage,
    openedAt: openedAt ?? DateTime(2026, 8, 17, 1, 42),
  );
}
