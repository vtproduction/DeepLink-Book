import 'dart:async';

import 'package:deep_link_book/app/app.dart';
import 'package:deep_link_book/app/router.dart';
import 'package:deep_link_book/core/database/app_database.dart';
import 'package:deep_link_book/core/database/database_provider.dart';
import 'package:deep_link_book/features/deeplinks/data/deeplink_repository.dart';
import 'package:deep_link_book/features/deeplinks/providers/deeplink_providers.dart';
import 'package:deep_link_book/features/environments/providers/environment_providers.dart';
import 'package:deep_link_book/features/projects/providers/project_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('renders the Add Deeplink form', (WidgetTester tester) async {
    await pumpAppOnAddScreen(tester);

    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Deeplink URL'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
  });

  testWidgets('shows validation messages for empty submission', (
    WidgetTester tester,
  ) async {
    await pumpAppOnAddScreen(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();

    expect(find.text('Enter a name.'), findsOneWidget);
    expect(find.text('Enter a deeplink URL.'), findsOneWidget);
  });

  testWidgets('shows validation message for invalid URL', (
    WidgetTester tester,
  ) async {
    await pumpAppOnAddScreen(tester);

    await tester.enterText(find.bySemanticsLabel('Name'), 'Transfer Out');
    await tester.enterText(
      find.bySemanticsLabel('Deeplink URL'),
      'transfer_out',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();

    expect(find.text('Enter a valid deeplink URL.'), findsOneWidget);
  });

  testWidgets('saves a deeplink and returns to Home', (
    WidgetTester tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DeeplinkRepository(database);

    await pumpAppOnAddScreen(
      tester,
      wrap: (child) {
        return ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            deeplinkRepositoryProvider.overrideWithValue(repository),
          ],
          child: child,
        );
      },
    );

    await tester.enterText(find.bySemanticsLabel('Name'), 'Transfer Out');
    await tester.enterText(
      find.bySemanticsLabel('Deeplink URL'),
      'ascendbank-qa://transfer_out',
    );
    await tester.enterText(
      find.bySemanticsLabel('Description'),
      'Open transfer flow',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final saved = await repository.getAllDeeplinks();

    expect(saved.single.name, 'Transfer Out');
    expect(saved.single.url, 'ascendbank-qa://transfer_out');
    expect(saved.single.description, 'Open transfer flow');
    expect(find.text('No deeplinks yet'), findsOneWidget);
  });

  testWidgets('saves an empty description as null', (
    WidgetTester tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DeeplinkRepository(database);

    await pumpAppOnAddScreen(
      tester,
      wrap: (child) {
        return ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            deeplinkRepositoryProvider.overrideWithValue(repository),
          ],
          child: child,
        );
      },
    );

    await tester.enterText(find.bySemanticsLabel('Name'), 'Profile');
    await tester.enterText(
      find.bySemanticsLabel('Deeplink URL'),
      'ascendbank-qa://profile',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final saved = await repository.getAllDeeplinks();

    expect(saved.single.description, isNull);
  });

  testWidgets('trims name, URL, and description before saving', (
    WidgetTester tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DeeplinkRepository(database);

    await pumpAppOnAddScreen(
      tester,
      wrap: (child) {
        return ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            deeplinkRepositoryProvider.overrideWithValue(repository),
          ],
          child: child,
        );
      },
    );

    await tester.enterText(find.bySemanticsLabel('Name'), '  Transfer Out  ');
    await tester.enterText(
      find.bySemanticsLabel('Deeplink URL'),
      '  ascendbank-qa://transfer_out  ',
    );
    await tester.enterText(
      find.bySemanticsLabel('Description'),
      '  Test transfer flow  ',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final saved = await repository.getAllDeeplinks();

    expect(saved.single.name, 'Transfer Out');
    expect(saved.single.url, 'ascendbank-qa://transfer_out');
    expect(saved.single.description, 'Test transfer flow');
  });

  testWidgets('disables Save and prevents repeated inserts while saving', (
    WidgetTester tester,
  ) async {
    final repository = ControlledDeeplinkRepository();
    addTearDown(repository.close);

    await pumpAppOnAddScreen(
      tester,
      wrap: (child) {
        return ProviderScope(
          overrides: [
            deeplinkRepositoryProvider.overrideWithValue(repository),
            deeplinksProvider.overrideWithValue(const AsyncValue.data([])),
          ],
          child: child,
        );
      },
    );

    await tester.enterText(find.bySemanticsLabel('Name'), 'Transfer Out');
    await tester.enterText(
      find.bySemanticsLabel('Deeplink URL'),
      'ascendbank-qa://transfer_out',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    final saveButton = tester.widget<FilledButton>(find.byType(FilledButton));

    expect(repository.createCallCount, 1);
    expect(saveButton.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repository.completeCreate();
    await tester.pumpAndSettle();
  });

  testWidgets('shows an error and stays on the form when save fails', (
    WidgetTester tester,
  ) async {
    final repository = FailingDeeplinkRepository();
    addTearDown(repository.close);

    await pumpAppOnAddScreen(
      tester,
      wrap: (child) {
        return ProviderScope(
          overrides: [
            deeplinkRepositoryProvider.overrideWithValue(repository),
            deeplinksProvider.overrideWithValue(const AsyncValue.data([])),
          ],
          child: child,
        );
      },
    );

    await tester.enterText(find.bySemanticsLabel('Name'), 'Transfer Out');
    await tester.enterText(
      find.bySemanticsLabel('Deeplink URL'),
      'ascendbank-qa://transfer_out',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final saveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save'),
    );

    expect(find.text('Add Deeplink'), findsOneWidget);
    expect(find.text('Unable to save deeplink.'), findsOneWidget);
    expect(saveButton.onPressed, isNotNull);
  });
}

Future<void> pumpAppOnAddScreen(
  WidgetTester tester, {
  Widget Function(Widget child)? wrap,
}) async {
  final app = ProviderScope(
    overrides: [
      deeplinksProvider.overrideWithValue(const AsyncValue.data([])),
      projectsProvider.overrideWithValue(AsyncValue.data([_testProject()])),
      environmentsForCurrentProjectProvider.overrideWithValue(
        const AsyncValue.data([]),
      ),
      environmentsForProjectProvider(
        1,
      ).overrideWithValue(const AsyncValue.data([])),
    ],
    child: App(router: createAppRouter()),
  );

  await tester.pumpWidget(wrap?.call(app) ?? app);

  await tester.tap(find.byTooltip('Add deeplink'));
  await tester.pumpAndSettle();
}

class ControlledDeeplinkRepository extends DeeplinkRepository {
  ControlledDeeplinkRepository() : this._(AppDatabase(NativeDatabase.memory()));

  // ignore: use_super_parameters
  ControlledDeeplinkRepository._(AppDatabase database)
    : _database = database,
      super(database);

  final AppDatabase _database;
  final _createCompleter = Completer<int>();
  var createCallCount = 0;

  @override
  Future<int> createDeeplink({
    int? projectId,
    int? environmentId,
    required String name,
    required String url,
    String? description,
  }) {
    createCallCount++;
    return _createCompleter.future;
  }

  void completeCreate() {
    if (!_createCompleter.isCompleted) {
      _createCompleter.complete(1);
    }
  }

  Future<void> close() => _database.close();
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

class FailingDeeplinkRepository extends DeeplinkRepository {
  FailingDeeplinkRepository() : this._(AppDatabase(NativeDatabase.memory()));

  // ignore: use_super_parameters
  FailingDeeplinkRepository._(AppDatabase database)
    : _database = database,
      super(database);

  final AppDatabase _database;

  @override
  Future<int> createDeeplink({
    int? projectId,
    int? environmentId,
    required String name,
    required String url,
    String? description,
  }) {
    throw Exception('Save failed');
  }

  Future<void> close() => _database.close();
}
