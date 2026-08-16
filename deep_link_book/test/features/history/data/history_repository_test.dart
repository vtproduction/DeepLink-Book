import 'package:deep_link_book/core/database/app_database.dart';
import 'package:deep_link_book/core/database/database_provider.dart';
import 'package:deep_link_book/features/deeplinks/data/deeplink_repository.dart';
import 'package:deep_link_book/features/history/data/history_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late HistoryRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = HistoryRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('provider creates a HistoryRepository from the app database', () {
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    final repository = container.read(historyRepositoryProvider);

    expect(repository, isA<HistoryRepository>());
  });

  test('creates successful history with a snapshot', () async {
    final id = await repository.createHistory(
      deeplinkId: 10,
      name: 'Transfer Out',
      url: 'deeplinktest://transfer?id=123',
      isSuccess: true,
    );

    final history = await database
        .select(database.deeplinkHistories)
        .getSingle();

    expect(id, isPositive);
    expect(history.deeplinkId, 10);
    expect(history.name, 'Transfer Out');
    expect(history.url, 'deeplinktest://transfer?id=123');
    expect(history.isSuccess, isTrue);
    expect(history.errorMessage, isNull);
    expect(history.openedAt, isNotNull);
  });

  test('creates failed history with an error message', () async {
    await repository.createHistory(
      deeplinkId: 10,
      name: 'Transfer Out',
      url: 'deeplinktest://transfer?id=123',
      isSuccess: false,
      errorMessage: 'No app can open this deeplink.',
    );

    final history = await database
        .select(database.deeplinkHistories)
        .getSingle();

    expect(history.deeplinkId, 10);
    expect(history.name, 'Transfer Out');
    expect(history.url, 'deeplinktest://transfer?id=123');
    expect(history.isSuccess, isFalse);
    expect(history.errorMessage, 'No app can open this deeplink.');
  });

  test('allows nullable deeplink id', () async {
    await repository.createHistory(
      name: 'Quick Open',
      url: 'deeplinktest://profile',
      isSuccess: true,
    );

    final history = await database
        .select(database.deeplinkHistories)
        .getSingle();

    expect(history.deeplinkId, isNull);
    expect(history.name, 'Quick Open');
  });

  test('keeps history snapshot after source deeplink changes', () async {
    final deeplinkRepository = DeeplinkRepository(database);
    final deeplinkId = await deeplinkRepository.createDeeplink(
      name: 'Transfer QA',
      url: 'deeplinktest://transfer?env=qa',
    );
    final deeplink = await deeplinkRepository.getDeeplinkById(deeplinkId);

    await repository.createHistory(
      deeplinkId: deeplink!.id,
      name: deeplink.name,
      url: deeplink.url,
      isSuccess: true,
    );
    await deeplinkRepository.updateDeeplink(
      id: deeplinkId,
      name: 'Transfer UAT',
      url: 'deeplinktest://transfer?env=uat',
    );

    final history = await repository.getAllHistory();

    expect(history.single.deeplinkId, deeplinkId);
    expect(history.single.name, 'Transfer QA');
    expect(history.single.url, 'deeplinktest://transfer?env=qa');
  });

  test(
    'gets history ordered by openedAt descending then id descending',
    () async {
      await insertHistory(
        database,
        name: 'Old',
        openedAt: DateTime(2026, 8, 11, 10),
      );
      await insertHistory(
        database,
        name: 'Newest',
        openedAt: DateTime(2026, 8, 11, 12),
      );
      await insertHistory(
        database,
        name: 'Middle',
        openedAt: DateTime(2026, 8, 11, 11),
      );
      await insertHistory(
        database,
        name: 'Newest Tie',
        openedAt: DateTime(2026, 8, 11, 12),
      );

      final history = await repository.getAllHistory();

      expect(history.map((item) => item.name), [
        'Newest Tie',
        'Newest',
        'Middle',
        'Old',
      ]);
    },
  );

  test('watches history as the table changes', () async {
    final emittedLists = <List<DeeplinkHistory>>[];
    final subscription = repository.watchAllHistory().listen(emittedLists.add);
    addTearDown(subscription.cancel);

    await _waitForEmissionCount(emittedLists, 1);
    expect(emittedLists.last, isEmpty);

    final firstId = await repository.createHistory(
      name: 'Transfer',
      url: 'deeplinktest://transfer?id=123',
      isSuccess: true,
    );
    await _waitForEmissionCount(emittedLists, 2);
    expect(emittedLists.last.single.name, 'Transfer');

    await repository.createHistory(
      name: 'Profile',
      url: 'deeplinktest://profile',
      isSuccess: true,
    );
    await _waitForEmissionCount(emittedLists, 3);
    expect(emittedLists.last.map((item) => item.name), contains('Profile'));

    await repository.deleteHistory(firstId);
    await _waitForEmissionCount(emittedLists, 4);
    expect(emittedLists.last.map((item) => item.name), ['Profile']);
  });

  test('deletes one history item and returns false for missing id', () async {
    final firstId = await insertHistory(database, name: 'First');
    final secondId = await insertHistory(database, name: 'Second');

    final wasDeleted = await repository.deleteHistory(firstId);
    final missingDelete = await repository.deleteHistory(firstId);
    final remaining = await repository.getAllHistory();

    expect(wasDeleted, isTrue);
    expect(missingDelete, isFalse);
    expect(remaining.single.id, secondId);
    expect(remaining.single.name, 'Second');
  });

  test('clears history without deleting saved deeplinks', () async {
    final deeplinkRepository = DeeplinkRepository(database);
    await deeplinkRepository.createDeeplink(
      name: 'Transfer Out',
      url: 'deeplinktest://transfer',
    );
    await insertHistory(database, name: 'First');
    await insertHistory(database, name: 'Second');

    final deletedRows = await repository.clearHistory();
    final history = await repository.getAllHistory();
    final deeplinks = await deeplinkRepository.getAllDeeplinks();

    expect(deletedRows, 2);
    expect(history, isEmpty);
    expect(deeplinks.single.name, 'Transfer Out');
  });

  test('deleting source deeplink does not delete history', () async {
    final deeplinkRepository = DeeplinkRepository(database);
    final deeplinkId = await deeplinkRepository.createDeeplink(
      name: 'Transfer Out',
      url: 'deeplinktest://transfer',
    );

    await repository.createHistory(
      deeplinkId: deeplinkId,
      name: 'Transfer Out',
      url: 'deeplinktest://transfer',
      isSuccess: true,
    );
    await deeplinkRepository.deleteDeeplink(deeplinkId);

    final history = await repository.getAllHistory();
    final deletedDeeplink = await deeplinkRepository.getDeeplinkById(
      deeplinkId,
    );

    expect(deletedDeeplink, isNull);
    expect(history.single.deeplinkId, deeplinkId);
    expect(history.single.name, 'Transfer Out');
    expect(history.single.url, 'deeplinktest://transfer');
  });
}

Future<int> insertHistory(
  AppDatabase database, {
  int? deeplinkId,
  required String name,
  String url = 'deeplinktest://example',
  bool isSuccess = true,
  String? errorMessage,
  DateTime? openedAt,
}) {
  return database
      .into(database.deeplinkHistories)
      .insert(
        DeeplinkHistoriesCompanion.insert(
          deeplinkId: Value(deeplinkId),
          name: name,
          url: url,
          isSuccess: isSuccess,
          errorMessage: Value(errorMessage),
          openedAt: openedAt ?? DateTime(2026, 8, 11, 10),
        ),
      );
}

Future<void> _waitForEmissionCount(
  List<List<DeeplinkHistory>> emittedLists,
  int count,
) async {
  for (var attempt = 0; attempt < 50; attempt++) {
    if (emittedLists.length >= count) {
      return;
    }

    await Future<void>.delayed(Duration.zero);
  }

  fail('Expected at least $count stream emissions.');
}
