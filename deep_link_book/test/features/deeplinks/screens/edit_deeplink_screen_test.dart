import 'dart:async';

import 'package:deep_link_book/app/app.dart';
import 'package:deep_link_book/app/router.dart';
import 'package:deep_link_book/core/database/app_database.dart';
import 'package:deep_link_book/core/database/database_provider.dart';
import 'package:deep_link_book/features/deeplinks/data/deeplink_repository.dart';
import 'package:deep_link_book/features/deeplinks/providers/deeplink_providers.dart';
import 'package:deep_link_book/features/environments/providers/environment_providers.dart';
import 'package:deep_link_book/features/projects/providers/project_providers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens the Edit Deeplink screen from a Home item', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final repository = CountingUpdateRepository(deeplink);
    addTearDown(repository.close);

    await _pumpAppWithRepository(tester, repository, deeplinks: [deeplink]);

    await tester.tap(find.text('Transfer Out'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Deeplink'), findsOneWidget);
  });

  testWidgets('prefills existing deeplink values', (WidgetTester tester) async {
    final context = _createDatabaseContext();
    final id = await context.repository.createDeeplink(
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
      description: 'Open transfer flow',
    );

    await _openEditRoute(tester, context, id);

    expect(_textFieldValue(tester, 'Name'), 'Transfer Out');
    expect(
      _textFieldValue(tester, 'Deeplink URL'),
      'ascendbank-qa://transfer_out',
    );
    expect(_textFieldValue(tester, 'Description'), 'Open transfer flow');
  });

  testWidgets('saves edits and returns to Home', (WidgetTester tester) async {
    final context = _createDatabaseContext();
    final id = await context.repository.createDeeplink(
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
      description: 'Open transfer flow',
    );
    final initial = await context.repository.getDeeplinkById(id);
    final deeplinksStream = StreamController<List<Deeplink>>();
    addTearDown(deeplinksStream.close);

    await _pumpAppWithRepository(
      tester,
      context.repository,
      database: context.database,
      deeplinksStream: deeplinksStream.stream,
    );
    deeplinksStream.add([initial!]);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Transfer Out'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.bySemanticsLabel('Name'),
      'Transfer Out Updated',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final updated = await context.repository.getDeeplinkById(id);

    expect(updated?.name, 'Transfer Out Updated');
    expect(updated?.url, 'ascendbank-qa://transfer_out');
    expect(updated?.description, 'Open transfer flow');
    expect(find.widgetWithText(AppBar, 'Home'), findsOneWidget);

    deeplinksStream.add([updated!]);
    await tester.pumpAndSettle();

    expect(find.text('Transfer Out Updated'), findsOneWidget);
  });

  testWidgets('saves an empty edited description as null', (
    WidgetTester tester,
  ) async {
    final context = _createDatabaseContext();
    final id = await context.repository.createDeeplink(
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
      description: 'Open transfer flow',
    );

    await _openEditRoute(tester, context, id);
    await tester.enterText(find.bySemanticsLabel('Description'), '');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final updated = await context.repository.getDeeplinkById(id);

    expect(updated?.description, isNull);
  });

  testWidgets('reuses URL validation and skips update for invalid input', (
    WidgetTester tester,
  ) async {
    final repository = CountingUpdateRepository(
      _testDeeplink(
        id: 1,
        name: 'Transfer Out',
        url: 'ascendbank-qa://transfer_out',
      ),
    );
    addTearDown(repository.close);

    await _pumpAppWithRepository(
      tester,
      repository,
      initialLocation: '/deeplinks/1/edit',
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.bySemanticsLabel('Deeplink URL'),
      'transfer_out',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();

    expect(find.text('Enter a valid deeplink URL.'), findsOneWidget);
    expect(repository.updateCallCount, 0);
  });

  testWidgets('preserves metadata when saving an edit', (
    WidgetTester tester,
  ) async {
    final context = _createDatabaseContext();
    final createdAt = DateTime(2026, 8, 11, 10);
    final lastOpenedAt = DateTime(2026, 8, 11, 11);
    final id = await context.database
        .into(context.database.deeplinks)
        .insert(
          DeeplinksCompanion.insert(
            name: 'Transfer Out',
            url: 'ascendbank-qa://transfer_out',
            description: const Value('Open transfer flow'),
            isFavorite: const Value(true),
            openCount: const Value(3),
            lastOpenedAt: Value(lastOpenedAt),
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );

    await _openEditRoute(tester, context, id);
    await tester.enterText(
      find.bySemanticsLabel('Name'),
      'Transfer Out Updated',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final updated = await context.repository.getDeeplinkById(id);

    expect(updated?.name, 'Transfer Out Updated');
    expect(updated?.isFavorite, isTrue);
    expect(updated?.openCount, 3);
    expect(updated?.lastOpenedAt, lastOpenedAt);
    expect(updated?.createdAt, createdAt);
  });

  testWidgets('shows not found when the deeplink is missing', (
    WidgetTester tester,
  ) async {
    await _pumpAppWithDatabase(tester, initialLocation: '/deeplinks/99/edit');
    await tester.pumpAndSettle();

    expect(find.text('Deeplink not found'), findsOneWidget);
  });

  testWidgets('handles an invalid route parameter gracefully', (
    WidgetTester tester,
  ) async {
    await _pumpAppWithDatabase(tester, initialLocation: '/deeplinks/abc/edit');
    await tester.pumpAndSettle();

    expect(find.text('Deeplink not found'), findsOneWidget);
    expect(find.text('The deeplink ID is invalid.'), findsOneWidget);
  });

  testWidgets('shows an error and keeps entered values when update fails', (
    WidgetTester tester,
  ) async {
    final repository = FailingUpdateRepository(
      _testDeeplink(
        id: 1,
        name: 'Transfer Out',
        url: 'ascendbank-qa://transfer_out',
      ),
    );
    addTearDown(repository.close);

    await _pumpAppWithRepository(
      tester,
      repository,
      initialLocation: '/deeplinks/1/edit',
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.bySemanticsLabel('Name'), 'Changed Name');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final saveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save'),
    );

    expect(find.text('Edit Deeplink'), findsOneWidget);
    expect(_textFieldValue(tester, 'Name'), 'Changed Name');
    expect(find.text('Unable to update deeplink.'), findsOneWidget);
    expect(saveButton.onPressed, isNotNull);
  });

  testWidgets('disables Save and prevents repeated updates while saving', (
    WidgetTester tester,
  ) async {
    final repository = ControlledUpdateRepository(
      _testDeeplink(
        id: 1,
        name: 'Transfer Out',
        url: 'ascendbank-qa://transfer_out',
      ),
    );
    addTearDown(repository.close);

    await _pumpAppWithRepository(
      tester,
      repository,
      initialLocation: '/deeplinks/1/edit',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    final saveButton = tester.widget<FilledButton>(find.byType(FilledButton));

    expect(repository.updateCallCount, 1);
    expect(saveButton.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repository.completeUpdate(wasUpdated: false);
    await tester.pumpAndSettle();
  });
}

Future<_DatabaseTestContext> _pumpAppWithDatabase(
  WidgetTester tester, {
  String? initialLocation,
}) async {
  final context = _createDatabaseContext();

  await _pumpAppWithRepository(
    tester,
    context.repository,
    database: context.database,
    initialLocation: initialLocation,
  );

  return context;
}

_DatabaseTestContext _createDatabaseContext() {
  final database = AppDatabase(NativeDatabase.memory());
  final repository = DeeplinkRepository(database);
  addTearDown(database.close);

  return _DatabaseTestContext(database: database, repository: repository);
}

Future<void> _pumpAppWithRepository(
  WidgetTester tester,
  DeeplinkRepository repository, {
  AppDatabase? database,
  List<Deeplink>? deeplinks,
  Stream<List<Deeplink>>? deeplinksStream,
  String? initialLocation,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (database != null) appDatabaseProvider.overrideWithValue(database),
        deeplinkRepositoryProvider.overrideWithValue(repository),
        if (deeplinks != null)
          deeplinksProvider.overrideWithValue(AsyncValue.data(deeplinks)),
        if (deeplinksStream != null)
          deeplinksProvider.overrideWith((ref) => deeplinksStream),
        projectsProvider.overrideWithValue(AsyncValue.data([_testProject()])),
        environmentsForCurrentProjectProvider.overrideWithValue(
          const AsyncValue.data([]),
        ),
        environmentsForProjectProvider(
          1,
        ).overrideWithValue(const AsyncValue.data([])),
      ],
      child: App(router: createAppRouter(initialLocation: initialLocation)),
    ),
  );
}

Future<void> _openEditRoute(
  WidgetTester tester,
  _DatabaseTestContext context,
  int id,
) async {
  await _pumpAppWithRepository(
    tester,
    context.repository,
    database: context.database,
    deeplinks: const [],
    initialLocation: '/deeplinks/$id/edit',
  );
  await tester.pumpAndSettle();
}

Deeplink _testDeeplink({
  required int id,
  required String name,
  required String url,
  String? description,
}) {
  final now = DateTime(2026, 8, 13, 10);

  return Deeplink(
    id: id,
    name: name,
    url: url,
    description: description,
    isFavorite: false,
    openCount: 0,
    createdAt: now,
    updatedAt: now,
  );
}

Project _testProject() {
  final now = DateTime(2026, 8, 15, 10);

  return Project(
    id: 1,
    name: AppDatabase.defaultProjectName,
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

String _textFieldValue(WidgetTester tester, String label) {
  final field = tester.widget<TextFormField>(
    find.widgetWithText(TextFormField, label),
  );

  return field.controller?.text ?? '';
}

class CountingUpdateRepository extends DeeplinkRepository {
  CountingUpdateRepository(Deeplink deeplink)
    : this._(deeplink, AppDatabase(NativeDatabase.memory()));

  // ignore: use_super_parameters
  CountingUpdateRepository._(this.deeplink, AppDatabase database)
    : _database = database,
      super(database);

  final Deeplink deeplink;
  final AppDatabase _database;
  var updateCallCount = 0;

  @override
  Future<Deeplink?> getDeeplinkById(int id) async {
    return id == deeplink.id ? deeplink : null;
  }

  @override
  Future<bool> updateDeeplink({
    required int id,
    int? projectId,
    Value<int?> environmentId = const Value.absent(),
    required String name,
    required String url,
    String? description,
  }) async {
    updateCallCount++;
    return true;
  }

  Future<void> close() => _database.close();
}

class FailingUpdateRepository extends CountingUpdateRepository {
  FailingUpdateRepository(super.deeplink);

  @override
  Future<bool> updateDeeplink({
    required int id,
    int? projectId,
    Value<int?> environmentId = const Value.absent(),
    required String name,
    required String url,
    String? description,
  }) {
    updateCallCount++;
    throw Exception('Update failed');
  }
}

class ControlledUpdateRepository extends CountingUpdateRepository {
  ControlledUpdateRepository(super.deeplink);

  final _updateCompleter = Completer<bool>();

  @override
  Future<bool> updateDeeplink({
    required int id,
    int? projectId,
    Value<int?> environmentId = const Value.absent(),
    required String name,
    required String url,
    String? description,
  }) {
    updateCallCount++;
    return _updateCompleter.future;
  }

  void completeUpdate({required bool wasUpdated}) {
    if (!_updateCompleter.isCompleted) {
      _updateCompleter.complete(wasUpdated);
    }
  }
}
