import 'dart:async';

import 'package:deep_link_book/app/app.dart';
import 'package:deep_link_book/app/router.dart';
import 'package:deep_link_book/core/database/app_database.dart';
import 'package:deep_link_book/core/database/database_provider.dart';
import 'package:deep_link_book/features/deeplinks/data/deeplink_repository.dart';
import 'package:deep_link_book/features/deeplinks/providers/deeplink_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows a Delete action in the item menu', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );

    await _pumpHome(tester, deeplinks: [deeplink]);
    await _openActionsMenu(tester, 'Transfer Out');

    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('shows a confirmation dialog before deleting', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );

    await _pumpHome(tester, deeplinks: [deeplink]);
    await _openDeleteDialog(tester, 'Transfer Out');

    expect(find.text('Delete deeplink?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Delete'), findsOneWidget);
  });

  testWidgets('cancel keeps the deeplink visible and in the database', (
    WidgetTester tester,
  ) async {
    final context = _createDatabaseContext();
    final id = await context.repository.createDeeplink(
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final deeplink = await context.repository.getDeeplinkById(id);

    await _pumpHome(
      tester,
      database: context.database,
      repository: context.repository,
      deeplinks: [deeplink!],
    );
    await _openDeleteDialog(tester, 'Transfer Out');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Transfer Out'), findsOneWidget);
    expect(await context.repository.getDeeplinkById(id), isNotNull);
  });

  testWidgets('confirm deletes from the repository and Home updates', (
    WidgetTester tester,
  ) async {
    final context = _createDatabaseContext();
    final id = await context.repository.createDeeplink(
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final deeplink = await context.repository.getDeeplinkById(id);
    final deeplinksStream = StreamController<List<Deeplink>>();
    addTearDown(deeplinksStream.close);

    await _pumpHome(
      tester,
      database: context.database,
      repository: context.repository,
      deeplinksStream: deeplinksStream.stream,
    );
    deeplinksStream.add([deeplink!]);
    await tester.pumpAndSettle();

    await _openDeleteDialog(tester, 'Transfer Out');
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(await context.repository.getDeeplinkById(id), isNull);

    deeplinksStream.add(const []);
    await tester.pumpAndSettle();

    expect(find.text('Transfer Out'), findsNothing);
  });

  testWidgets('deleting the last item shows the empty state', (
    WidgetTester tester,
  ) async {
    final context = _createDatabaseContext();
    final id = await context.repository.createDeeplink(
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final deeplink = await context.repository.getDeeplinkById(id);
    final deeplinksStream = StreamController<List<Deeplink>>();
    addTearDown(deeplinksStream.close);

    await _pumpHome(
      tester,
      database: context.database,
      repository: context.repository,
      deeplinksStream: deeplinksStream.stream,
    );
    deeplinksStream.add([deeplink!]);
    await tester.pumpAndSettle();

    await _openDeleteDialog(tester, 'Transfer Out');
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    deeplinksStream.add(const []);
    await tester.pumpAndSettle();

    expect(find.text('No deeplinks yet'), findsOneWidget);
  });

  testWidgets('shows a message when the deeplink is already missing', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final repository = MissingDeleteRepository(deeplink);
    addTearDown(repository.close);

    await _pumpHome(tester, repository: repository, deeplinks: [deeplink]);
    await _openDeleteDialog(tester, 'Transfer Out');
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('This deeplink no longer exists.'), findsOneWidget);
    expect(find.text('Transfer Out'), findsOneWidget);
  });

  testWidgets('shows an error when delete fails and re-enables the action', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final repository = FailingDeleteRepository(deeplink);
    addTearDown(repository.close);

    await _pumpHome(tester, repository: repository, deeplinks: [deeplink]);
    await _openDeleteDialog(tester, 'Transfer Out');
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Unable to delete deeplink.'), findsOneWidget);
    expect(find.text('Transfer Out'), findsOneWidget);
    expect(find.byTooltip('Actions for Transfer Out'), findsOneWidget);
  });

  testWidgets('prevents duplicate delete requests while deleting', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final repository = ControlledDeleteRepository(deeplink);
    addTearDown(repository.close);

    await _pumpHome(tester, repository: repository, deeplinks: [deeplink]);
    await _openDeleteDialog(tester, 'Transfer Out');
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pump();

    expect(repository.deleteCallCount, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byTooltip('Actions for Transfer Out'), findsNothing);

    repository.completeDelete(deleted: false);
    await tester.pumpAndSettle();

    expect(repository.deleteCallCount, 1);
    expect(find.byTooltip('Actions for Transfer Out'), findsOneWidget);
  });

  testWidgets('tapping the row still opens Edit Deeplink', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final repository = MissingDeleteRepository(deeplink);
    addTearDown(repository.close);

    await _pumpHome(tester, repository: repository, deeplinks: [deeplink]);
    await tester.tap(find.text('Transfer Out'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Deeplink'), findsOneWidget);
  });
}

Future<void> _pumpHome(
  WidgetTester tester, {
  AppDatabase? database,
  DeeplinkRepository? repository,
  List<Deeplink>? deeplinks,
  Stream<List<Deeplink>>? deeplinksStream,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (database != null) appDatabaseProvider.overrideWithValue(database),
        if (repository != null)
          deeplinkRepositoryProvider.overrideWithValue(repository),
        if (deeplinks != null)
          deeplinksProvider.overrideWithValue(AsyncValue.data(deeplinks)),
        if (deeplinksStream != null)
          deeplinksProvider.overrideWith((ref) => deeplinksStream),
      ],
      child: App(router: createAppRouter()),
    ),
  );
}

Future<void> _openActionsMenu(WidgetTester tester, String name) async {
  await tester.tap(find.byTooltip('Actions for $name'));
  await tester.pumpAndSettle();
}

Future<void> _openDeleteDialog(WidgetTester tester, String name) async {
  await _openActionsMenu(tester, name);
  await tester.tap(find.text('Delete'));
  await tester.pumpAndSettle();
}

_DatabaseTestContext _createDatabaseContext() {
  final database = AppDatabase(NativeDatabase.memory());
  final repository = DeeplinkRepository(database);
  addTearDown(database.close);

  return _DatabaseTestContext(database: database, repository: repository);
}

Deeplink _testDeeplink({
  required int id,
  required String name,
  required String url,
}) {
  final now = DateTime(2026, 8, 15, 10);

  return Deeplink(
    id: id,
    name: name,
    url: url,
    isFavorite: false,
    openCount: 0,
    createdAt: now,
    updatedAt: now,
  );
}

class _DatabaseTestContext {
  const _DatabaseTestContext({
    required this.database,
    required this.repository,
  });

  final AppDatabase database;
  final DeeplinkRepository repository;
}

class MissingDeleteRepository extends DeeplinkRepository {
  MissingDeleteRepository(Deeplink deeplink)
    : this._(deeplink, AppDatabase(NativeDatabase.memory()));

  // ignore: use_super_parameters
  MissingDeleteRepository._(this.deeplink, AppDatabase database)
    : _database = database,
      super(database);

  final Deeplink deeplink;
  final AppDatabase _database;
  var deleteCallCount = 0;

  @override
  Future<Deeplink?> getDeeplinkById(int id) async {
    return id == deeplink.id ? deeplink : null;
  }

  @override
  Future<bool> deleteDeeplink(int id) async {
    deleteCallCount++;
    return false;
  }

  Future<void> close() => _database.close();
}

class FailingDeleteRepository extends MissingDeleteRepository {
  FailingDeleteRepository(super.deeplink);

  @override
  Future<bool> deleteDeeplink(int id) {
    deleteCallCount++;
    throw Exception('Delete failed');
  }
}

class ControlledDeleteRepository extends MissingDeleteRepository {
  ControlledDeleteRepository(super.deeplink);

  final _deleteCompleter = Completer<bool>();

  @override
  Future<bool> deleteDeeplink(int id) {
    deleteCallCount++;
    return _deleteCompleter.future;
  }

  void completeDelete({required bool deleted}) {
    if (!_deleteCompleter.isCompleted) {
      _deleteCompleter.complete(deleted);
    }
  }
}
