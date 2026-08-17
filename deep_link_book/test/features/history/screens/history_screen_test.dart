import 'dart:async';

import 'package:deep_link_book/app/theme/app_theme.dart';
import 'package:deep_link_book/core/database/app_database.dart';
import 'package:deep_link_book/core/database/database_provider.dart';
import 'package:deep_link_book/core/deeplink/deeplink_launcher.dart';
import 'package:deep_link_book/features/deeplinks/data/deeplink_repository.dart';
import 'package:deep_link_book/features/history/data/history_repository.dart';
import 'package:deep_link_book/features/history/providers/history_providers.dart';
import 'package:deep_link_book/features/history/screens/history_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
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
    expect(find.widgetWithText(FilledButton, 'Open'), findsOneWidget);
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

  testWidgets('reopens a history snapshot and creates a new successful row', (
    WidgetTester tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final launcher = TestDeeplinkLauncher();
    final repository = HistoryRepository(database);
    addTearDown(database.close);

    await repository.createHistory(
      deeplinkId: 10,
      name: 'Transfer Out',
      url: 'deeplinktest://transfer?id=123',
      isSuccess: true,
    );
    final originalHistory = await repository.getAllHistory();

    await pumpHistoryScreen(tester, database: database, launcher: launcher);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Open'));
    await tester.pumpAndSettle();

    final history = await repository.getAllHistory();

    expect(launcher.openedUris, [Uri.parse('deeplinktest://transfer?id=123')]);
    expect(history, hasLength(2));
    expect(history.last.id, originalHistory.single.id);
    expect(history.last.openedAt, originalHistory.single.openedAt);
    expect(history.first.name, 'Transfer Out');
    expect(history.first.url, 'deeplinktest://transfer?id=123');
    expect(history.first.deeplinkId, 10);
    expect(history.first.isSuccess, isTrue);
    expect(history.first.errorMessage, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('reopens a history snapshot without a source deeplink', (
    WidgetTester tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final launcher = TestDeeplinkLauncher();
    final repository = HistoryRepository(database);
    addTearDown(database.close);

    await repository.createHistory(
      name: 'Quick Open',
      url: 'deeplinktest://profile',
      isSuccess: true,
    );

    await pumpHistoryScreen(tester, database: database, launcher: launcher);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Open'));
    await tester.pumpAndSettle();

    final history = await repository.getAllHistory();

    expect(launcher.openedUris, [Uri.parse('deeplinktest://profile')]);
    expect(history.first.deeplinkId, isNull);
    expect(history.first.name, 'Quick Open');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets(
    'reopens a history snapshot after the source deeplink is deleted',
    (WidgetTester tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      final launcher = TestDeeplinkLauncher();
      final historyRepository = HistoryRepository(database);
      final deeplinkRepository = DeeplinkRepository(database);
      addTearDown(database.close);

      final deeplinkId = await deeplinkRepository.createDeeplink(
        name: 'Transfer QA',
        url: 'deeplinktest://transfer?env=qa',
      );
      await historyRepository.createHistory(
        deeplinkId: deeplinkId,
        name: 'Transfer QA',
        url: 'deeplinktest://transfer?env=qa',
        isSuccess: true,
      );
      await deeplinkRepository.deleteDeeplink(deeplinkId);

      await pumpHistoryScreen(tester, database: database, launcher: launcher);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Open'));
      await tester.pumpAndSettle();

      final history = await historyRepository.getAllHistory();

      expect(launcher.openedUris, [
        Uri.parse('deeplinktest://transfer?env=qa'),
      ]);
      expect(history.first.deeplinkId, deeplinkId);
      expect(history.first.isSuccess, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  testWidgets('records failed history when reopen launcher returns false', (
    WidgetTester tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final launcher = TestDeeplinkLauncher(openResult: false);
    final repository = HistoryRepository(database);
    addTearDown(database.close);

    await repository.createHistory(
      name: 'Profile',
      url: 'deeplinktest://profile',
      isSuccess: true,
    );

    await pumpHistoryScreen(tester, database: database, launcher: launcher);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Open'));
    await tester.pumpAndSettle();

    final history = await repository.getAllHistory();

    expect(history, hasLength(2));
    expect(history.first.isSuccess, isFalse);
    expect(history.first.errorMessage, 'No app can open this deeplink.');
    expect(find.text('No app can open this deeplink.'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('does not launch invalid history URLs and records failure', (
    WidgetTester tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final launcher = TestDeeplinkLauncher();
    final repository = HistoryRepository(database);
    addTearDown(database.close);

    await repository.createHistory(
      name: 'Broken',
      url: 'not a url',
      isSuccess: false,
      errorMessage: 'Old failure',
    );

    await pumpHistoryScreen(tester, database: database, launcher: launcher);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Open'));
    await tester.pumpAndSettle();

    final history = await repository.getAllHistory();

    expect(launcher.openedUris, isEmpty);
    expect(history, hasLength(2));
    expect(history.first.isSuccess, isFalse);
    expect(history.first.errorMessage, 'Invalid deeplink URL.');
    expect(find.text('Enter a valid deeplink URL.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('records failed history when launcher throws', (
    WidgetTester tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final launcher = TestDeeplinkLauncher(throwsOnOpen: true);
    final repository = HistoryRepository(database);
    addTearDown(database.close);

    await repository.createHistory(
      name: 'Transfer',
      url: 'deeplinktest://transfer',
      isSuccess: true,
    );

    await pumpHistoryScreen(tester, database: database, launcher: launcher);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Open'));
    await tester.pumpAndSettle();

    final history = await repository.getAllHistory();

    expect(history, hasLength(2));
    expect(history.first.isSuccess, isFalse);
    expect(history.first.errorMessage, 'Unable to open deeplink.');
    expect(find.text('Unable to open deeplink.'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('reopening from history does not change saved deeplink usage', (
    WidgetTester tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final launcher = TestDeeplinkLauncher();
    final historyRepository = HistoryRepository(database);
    final deeplinkRepository = DeeplinkRepository(database);
    addTearDown(database.close);

    final deeplinkId = await deeplinkRepository.createDeeplink(
      name: 'Transfer',
      url: 'deeplinktest://transfer',
    );
    final beforeOpen = await deeplinkRepository.getDeeplinkById(deeplinkId);
    await historyRepository.createHistory(
      deeplinkId: deeplinkId,
      name: 'Transfer',
      url: 'deeplinktest://transfer',
      isSuccess: true,
    );

    await pumpHistoryScreen(tester, database: database, launcher: launcher);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Open'));
    await tester.pumpAndSettle();

    final afterOpen = await deeplinkRepository.getDeeplinkById(deeplinkId);

    expect(afterOpen!.openCount, beforeOpen!.openCount);
    expect(afterOpen.lastOpenedAt, beforeOpen.lastOpenedAt);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('prevents repeated open taps while launch is pending', (
    WidgetTester tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final launcher = TestDeeplinkLauncher(isPending: true);
    final repository = HistoryRepository(database);
    addTearDown(database.close);

    await repository.createHistory(
      name: 'Transfer',
      url: 'deeplinktest://transfer',
      isSuccess: true,
    );

    await pumpHistoryScreen(tester, database: database, launcher: launcher);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Open'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Opening'));
    await tester.pump();

    expect(launcher.openCallCount, 1);

    launcher.completePendingOpen(true);
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('delete action shows confirmation and cancel keeps item', (
    WidgetTester tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = HistoryRepository(database);
    addTearDown(database.close);

    await repository.createHistory(
      name: 'Transfer',
      url: 'deeplinktest://transfer',
      isSuccess: true,
    );

    await pumpHistoryScreen(tester, database: database);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('History actions'));
    await tester.pumpAndSettle();

    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete history item?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    final history = await repository.getAllHistory();

    expect(history, hasLength(1));
    expect(find.text('Transfer'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('copy action exists and copies the History snapshot URL', (
    WidgetTester tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final launcher = TestDeeplinkLauncher();
    final historyRepository = HistoryRepository(database);
    final deeplinkRepository = DeeplinkRepository(database);
    addTearDown(database.close);

    final deeplinkId = await deeplinkRepository.createDeeplink(
      name: 'Transfer QA',
      url: 'deeplinktest://transfer?env=qa',
    );
    await historyRepository.createHistory(
      deeplinkId: deeplinkId,
      name: 'Transfer QA',
      url: 'deeplinktest://transfer?env=qa',
      isSuccess: true,
    );
    await deeplinkRepository.updateDeeplink(
      id: deeplinkId,
      name: 'Transfer UAT',
      url: 'deeplinktest://transfer?env=uat',
    );

    final clipboardWrites = captureClipboardWrites();
    await pumpHistoryScreen(tester, database: database, launcher: launcher);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('History actions'));
    await tester.pumpAndSettle();

    expect(find.text('Copy'), findsOneWidget);

    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();

    final history = await historyRepository.getAllHistory();

    expect(clipboardWrites, ['deeplinktest://transfer?env=qa']);
    expect(find.text('Deeplink copied.'), findsOneWidget);
    expect(find.text('Delete history item?'), findsNothing);
    expect(launcher.openedUris, isEmpty);
    expect(history, hasLength(1));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('confirming delete removes one history item', (
    WidgetTester tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = HistoryRepository(database);
    addTearDown(database.close);

    await repository.createHistory(
      name: 'Transfer',
      url: 'deeplinktest://transfer',
      isSuccess: true,
    );
    await repository.createHistory(
      name: 'Profile',
      url: 'deeplinktest://profile',
      isSuccess: true,
    );

    await pumpHistoryScreen(tester, database: database);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('History actions').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    final history = await repository.getAllHistory();

    expect(history, hasLength(1));
    expect(find.text('Profile'), findsNothing);
    expect(find.text('Transfer'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('shows feedback when delete reports a missing row', (
    WidgetTester tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = TestHistoryRepository(database, deleteResult: false);
    addTearDown(database.close);

    await pumpHistoryScreen(
      tester,
      historyRepository: repository,
      history: [
        testHistory(id: 404, name: 'Missing', url: 'deeplinktest://missing'),
      ],
    );

    await tester.tap(find.byTooltip('History actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(find.text('This history item no longer exists.'), findsOneWidget);
    expect(find.text('Missing'), findsOneWidget);
  });

  testWidgets('shows feedback when delete throws', (WidgetTester tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = TestHistoryRepository(database, throwsOnDelete: true);
    addTearDown(database.close);

    await pumpHistoryScreen(
      tester,
      historyRepository: repository,
      history: [
        testHistory(id: 1, name: 'Transfer', url: 'deeplinktest://transfer'),
      ],
    );

    await tester.tap(find.byTooltip('History actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(find.text('Unable to delete history item.'), findsOneWidget);
    expect(find.text('Transfer'), findsOneWidget);
    expect(find.byTooltip('History actions'), findsOneWidget);
  });

  testWidgets('clear history action confirms and cancel keeps rows', (
    WidgetTester tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = HistoryRepository(database);
    addTearDown(database.close);

    await repository.createHistory(
      name: 'Transfer',
      url: 'deeplinktest://transfer',
      isSuccess: true,
    );

    await pumpHistoryScreen(tester, database: database);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Clear history'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear history'));
    await tester.pumpAndSettle();

    expect(find.text('Clear all history?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    final history = await repository.getAllHistory();

    expect(history, hasLength(1));
    expect(find.text('Transfer'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('confirming clear removes history and keeps saved deeplinks', (
    WidgetTester tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final historyRepository = HistoryRepository(database);
    final deeplinkRepository = DeeplinkRepository(database);
    addTearDown(database.close);

    await deeplinkRepository.createDeeplink(
      name: 'Transfer Deeplink',
      url: 'deeplinktest://transfer',
    );
    await historyRepository.createHistory(
      name: 'Transfer',
      url: 'deeplinktest://transfer',
      isSuccess: true,
    );
    await historyRepository.createHistory(
      name: 'Profile',
      url: 'deeplinktest://profile',
      isSuccess: true,
    );

    await pumpHistoryScreen(tester, database: database);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Clear history'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    final history = await historyRepository.getAllHistory();
    final deeplinks = await deeplinkRepository.getAllDeeplinks();

    expect(history, isEmpty);
    expect(deeplinks.single.name, 'Transfer Deeplink');
    expect(find.text('No history yet'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('shows feedback when clear history throws', (
    WidgetTester tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = TestHistoryRepository(database, throwsOnClear: true);
    addTearDown(database.close);

    await pumpHistoryScreen(
      tester,
      historyRepository: repository,
      history: [
        testHistory(id: 1, name: 'Transfer', url: 'deeplinktest://transfer'),
      ],
    );

    await tester.tap(find.byTooltip('Clear history'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(find.text('Unable to clear history.'), findsOneWidget);
    expect(find.text('Transfer'), findsOneWidget);
    expect(find.byTooltip('Clear history'), findsOneWidget);
  });
}

List<String?> captureClipboardWrites() {
  final clipboardWrites = <String?>[];

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          final arguments = call.arguments as Map<Object?, Object?>;
          clipboardWrites.add(arguments['text'] as String?);
        }

        return null;
      });
  addTearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  return clipboardWrites;
}

Future<void> pumpHistoryScreen(
  WidgetTester tester, {
  AppDatabase? database,
  DeeplinkLauncher? launcher,
  HistoryRepository? historyRepository,
  List<DeeplinkHistory>? history,
  AsyncValue<List<DeeplinkHistory>>? historyValue,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (database != null) appDatabaseProvider.overrideWithValue(database),
        if (launcher != null)
          deeplinkLauncherProvider.overrideWithValue(launcher),
        if (historyRepository != null)
          historyRepositoryProvider.overrideWithValue(historyRepository),
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

class TestDeeplinkLauncher extends DeeplinkLauncher {
  TestDeeplinkLauncher({
    this.openResult = true,
    this.throwsOnOpen = false,
    this.isPending = false,
  });

  final bool openResult;
  final bool throwsOnOpen;
  final bool isPending;
  final openedUris = <Uri>[];
  Completer<bool>? _pendingOpen;

  int get openCallCount => openedUris.length;

  @override
  Future<bool> open(Uri uri) {
    openedUris.add(uri);

    if (throwsOnOpen) {
      throw Exception('Launcher failed');
    }

    if (isPending) {
      _pendingOpen ??= Completer<bool>();
      return _pendingOpen!.future;
    }

    return Future.value(openResult);
  }

  void completePendingOpen(bool result) {
    _pendingOpen?.complete(result);
  }
}

class TestHistoryRepository extends HistoryRepository {
  TestHistoryRepository(
    super.database, {
    this.deleteResult = true,
    this.throwsOnDelete = false,
    this.throwsOnClear = false,
  });

  final bool deleteResult;
  final bool throwsOnDelete;
  final bool throwsOnClear;

  @override
  Future<bool> deleteHistory(int id) {
    if (throwsOnDelete) {
      throw Exception('Delete failed');
    }

    return Future.value(deleteResult);
  }

  @override
  Future<int> clearHistory() {
    if (throwsOnClear) {
      throw Exception('Clear failed');
    }

    return Future.value(0);
  }
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
