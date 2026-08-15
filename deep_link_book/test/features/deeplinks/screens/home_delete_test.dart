import 'dart:async';

import 'package:deep_link_book/app/app.dart';
import 'package:deep_link_book/app/router.dart';
import 'package:deep_link_book/core/database/app_database.dart';
import 'package:deep_link_book/core/database/database_provider.dart';
import 'package:deep_link_book/features/deeplinks/data/deeplink_repository.dart';
import 'package:deep_link_book/features/deeplinks/providers/deeplink_providers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows item menu actions', (WidgetTester tester) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );

    await _pumpHome(tester, deeplinks: [deeplink]);
    await _openActionsMenu(tester, 'Transfer Out');

    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Duplicate'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('duplicates a deeplink through the repository', (
    WidgetTester tester,
  ) async {
    final context = _createDatabaseContext();
    final id = await context.repository.createDeeplink(
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
      description: 'Open transfer flow',
    );
    final deeplink = await context.repository.getDeeplinkById(id);

    await _pumpHome(
      tester,
      database: context.database,
      repository: context.repository,
      deeplinks: [deeplink!],
    );
    await _openActionsMenu(tester, 'Transfer Out');
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();

    final saved = await context.repository.getAllDeeplinks();
    final original = saved.singleWhere((deeplink) => deeplink.id == id);
    final copy = saved.singleWhere((deeplink) => deeplink.id != id);

    expect(saved, hasLength(2));
    expect(copy.id, isNot(original.id));
    expect(copy.name, 'Transfer Out (Copy)');
    expect(copy.url, original.url);
    expect(copy.description, 'Open transfer flow');
  });

  testWidgets('duplicate resets metadata and keeps the original unchanged', (
    WidgetTester tester,
  ) async {
    final context = _createDatabaseContext();
    final createdAt = DateTime(2026, 8, 15, 10);
    final lastOpenedAt = DateTime(2026, 8, 15, 11);
    final id = await context.database
        .into(context.database.deeplinks)
        .insert(
          DeeplinksCompanion.insert(
            name: 'Transfer Out',
            url: 'ascendbank-qa://transfer_out',
            description: const Value('Open transfer flow'),
            isFavorite: const Value(true),
            openCount: const Value(5),
            lastOpenedAt: Value(lastOpenedAt),
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );
    final deeplink = await context.repository.getDeeplinkById(id);

    await _pumpHome(
      tester,
      database: context.database,
      repository: context.repository,
      deeplinks: [deeplink!],
    );
    await _openActionsMenu(tester, 'Transfer Out');
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();

    final saved = await context.repository.getAllDeeplinks();
    final original = saved.singleWhere((deeplink) => deeplink.id == id);
    final copy = saved.singleWhere((deeplink) => deeplink.id != id);

    expect(original.isFavorite, isTrue);
    expect(original.openCount, 5);
    expect(original.lastOpenedAt, lastOpenedAt);
    expect(original.createdAt, createdAt);
    expect(copy.isFavorite, isFalse);
    expect(copy.openCount, 0);
    expect(copy.lastOpenedAt, isNull);
    expect(copy.createdAt, isNot(createdAt));
    expect(copy.updatedAt, isNot(createdAt));
  });

  testWidgets('duplicate preserves a null description', (
    WidgetTester tester,
  ) async {
    final context = _createDatabaseContext();
    final id = await context.repository.createDeeplink(
      name: 'Profile',
      url: 'ascendbank-qa://profile',
    );
    final deeplink = await context.repository.getDeeplinkById(id);

    await _pumpHome(
      tester,
      database: context.database,
      repository: context.repository,
      deeplinks: [deeplink!],
    );
    await _openActionsMenu(tester, 'Profile');
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();

    final saved = await context.repository.getAllDeeplinks();
    final copy = saved.singleWhere((deeplink) => deeplink.id != id);

    expect(copy.description, isNull);
  });

  testWidgets('Home shows the duplicated item from the stream', (
    WidgetTester tester,
  ) async {
    final context = _createDatabaseContext();
    final id = await context.repository.createDeeplink(
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
      description: 'Open transfer flow',
    );
    final original = await context.repository.getDeeplinkById(id);
    final deeplinksStream = StreamController<List<Deeplink>>();
    addTearDown(deeplinksStream.close);

    await _pumpHome(
      tester,
      database: context.database,
      repository: context.repository,
      deeplinksStream: deeplinksStream.stream,
    );
    deeplinksStream.add([original!]);
    await tester.pumpAndSettle();

    await _openActionsMenu(tester, 'Transfer Out');
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();

    final updatedList = await context.repository.getAllDeeplinks();
    deeplinksStream.add(updatedList);
    await tester.pumpAndSettle();

    expect(find.text('Transfer Out'), findsOneWidget);
    expect(find.text('Transfer Out (Copy)'), findsOneWidget);
  });

  testWidgets('shows a message when duplicating a missing source', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final repository = MissingDuplicateRepository(deeplink);
    addTearDown(repository.close);

    await _pumpHome(tester, repository: repository, deeplinks: [deeplink]);
    await _openActionsMenu(tester, 'Transfer Out');
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();

    expect(find.text('This deeplink no longer exists.'), findsOneWidget);
    expect(find.text('Transfer Out'), findsOneWidget);
  });

  testWidgets('shows an error when duplicate fails and re-enables the action', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final repository = FailingDuplicateRepository(deeplink);
    addTearDown(repository.close);

    await _pumpHome(tester, repository: repository, deeplinks: [deeplink]);
    await _openActionsMenu(tester, 'Transfer Out');
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();

    expect(find.text('Unable to duplicate deeplink.'), findsOneWidget);
    expect(find.text('Transfer Out'), findsOneWidget);
    expect(find.byTooltip('Actions for Transfer Out'), findsOneWidget);
  });

  testWidgets('prevents repeated duplicate requests while processing', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final repository = ControlledDuplicateRepository(deeplink);
    addTearDown(repository.close);

    await _pumpHome(tester, repository: repository, deeplinks: [deeplink]);
    await _openActionsMenu(tester, 'Transfer Out');
    await tester.tap(find.text('Duplicate'));
    await tester.pump();

    expect(repository.duplicateCallCount, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byTooltip('Actions for Transfer Out'), findsNothing);

    repository.completeDuplicate(duplicatedId: null);
    await tester.pumpAndSettle();

    expect(repository.duplicateCallCount, 1);
    expect(find.byTooltip('Actions for Transfer Out'), findsOneWidget);
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

class MissingDuplicateRepository extends DeeplinkRepository {
  MissingDuplicateRepository(Deeplink deeplink)
    : this._(deeplink, AppDatabase(NativeDatabase.memory()));

  // ignore: use_super_parameters
  MissingDuplicateRepository._(this.deeplink, AppDatabase database)
    : _database = database,
      super(database);

  final Deeplink deeplink;
  final AppDatabase _database;
  var duplicateCallCount = 0;

  @override
  Future<Deeplink?> getDeeplinkById(int id) async {
    return id == deeplink.id ? deeplink : null;
  }

  @override
  Future<int?> duplicateDeeplink(int id) async {
    duplicateCallCount++;
    return null;
  }

  Future<void> close() => _database.close();
}

class FailingDuplicateRepository extends MissingDuplicateRepository {
  FailingDuplicateRepository(super.deeplink);

  @override
  Future<int?> duplicateDeeplink(int id) {
    duplicateCallCount++;
    throw Exception('Duplicate failed');
  }
}

class ControlledDuplicateRepository extends MissingDuplicateRepository {
  ControlledDuplicateRepository(super.deeplink);

  final _duplicateCompleter = Completer<int?>();

  @override
  Future<int?> duplicateDeeplink(int id) {
    duplicateCallCount++;
    return _duplicateCompleter.future;
  }

  void completeDuplicate({required int? duplicatedId}) {
    if (!_duplicateCompleter.isCompleted) {
      _duplicateCompleter.complete(duplicatedId);
    }
  }
}
