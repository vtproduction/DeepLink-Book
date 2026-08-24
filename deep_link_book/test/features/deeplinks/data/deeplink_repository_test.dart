import 'package:deep_link_book/core/database/app_database.dart';
import 'package:deep_link_book/features/deeplinks/data/deeplink_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DeeplinkRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = DeeplinkRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates a deeplink with default persistence values', () async {
    final id = await repository.createDeeplink(
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );

    final deeplink = await repository.getDeeplinkById(id);

    expect(id, isPositive);
    expect(deeplink, isNotNull);
    expect(deeplink!.name, 'Transfer Out');
    expect(deeplink.url, 'ascendbank-qa://transfer_out');
    expect(deeplink.projectId, isNotNull);
    expect(deeplink.environmentId, isNull);
    expect(deeplink.isFavorite, isFalse);
    expect(deeplink.openCount, 0);
    expect(deeplink.lastOpenedAt, isNull);
    expect(deeplink.createdAt, isNotNull);
    expect(deeplink.updatedAt, isNotNull);

    final project = await database.select(database.projects).getSingle();

    expect(project.id, deeplink.projectId);
    expect(project.name, AppDatabase.defaultProjectName);
  });

  test('persists optional description when creating a deeplink', () async {
    final id = await repository.createDeeplink(
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
      description: 'Move money to another account',
    );

    final deeplink = await repository.getDeeplinkById(id);

    expect(deeplink?.description, 'Move money to another account');
  });

  test('gets a deeplink by id or returns null when missing', () async {
    final id = await repository.createDeeplink(
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );

    final existing = await repository.getDeeplinkById(id);
    final missing = await repository.getDeeplinkById(id + 1);

    expect(existing?.id, id);
    expect(missing, isNull);
  });

  test('gets all deeplinks ordered by updatedAt descending', () async {
    await insertDeeplink(
      database,
      name: 'Old',
      url: 'example://old',
      updatedAt: DateTime(2026, 8, 11, 10),
    );
    await insertDeeplink(
      database,
      name: 'New',
      url: 'example://new',
      updatedAt: DateTime(2026, 8, 11, 12),
    );
    await insertDeeplink(
      database,
      name: 'Middle',
      url: 'example://middle',
      updatedAt: DateTime(2026, 8, 11, 11),
    );

    final deeplinks = await repository.getAllDeeplinks();

    expect(deeplinks.map((deeplink) => deeplink.name), [
      'New',
      'Middle',
      'Old',
    ]);
  });

  test('watches all deeplinks as the table changes', () async {
    final emittedLists = <List<Deeplink>>[];
    final subscription = repository.watchAllDeeplinks().listen(
      emittedLists.add,
    );
    addTearDown(subscription.cancel);

    await _waitForEmissionCount(emittedLists, 1);
    expect(emittedLists.last, isEmpty);

    final id = await repository.createDeeplink(
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    await _waitForEmissionCount(emittedLists, 2);
    expect(emittedLists.last.single.name, 'Transfer Out');

    await repository.updateDeeplink(
      id: id,
      name: 'Transfer Out Updated',
      url: 'ascendbank-qa://transfer_out_updated',
    );
    await _waitForEmissionCount(emittedLists, 3);
    expect(emittedLists.last.single.name, 'Transfer Out Updated');

    await repository.deleteDeeplink(id);
    await _waitForEmissionCount(emittedLists, 4);
    expect(emittedLists.last, isEmpty);
  });

  test('updates deeplink fields while preserving existing state', () async {
    final createdAt = DateTime(2026, 8, 11, 10);
    final originalUpdatedAt = DateTime(2026, 8, 11, 10);
    final lastOpenedAt = DateTime(2026, 8, 11, 11);
    final id = await insertDeeplink(
      database,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
      description: 'Original description',
      isFavorite: true,
      openCount: 3,
      lastOpenedAt: lastOpenedAt,
      createdAt: createdAt,
      updatedAt: originalUpdatedAt,
    );

    final wasUpdated = await repository.updateDeeplink(
      id: id,
      name: 'Transfer Out Updated',
      url: 'ascendbank-qa://transfer_out_updated',
      description: 'Updated description',
    );
    final updated = await repository.getDeeplinkById(id);

    expect(wasUpdated, isTrue);
    expect(updated?.name, 'Transfer Out Updated');
    expect(updated?.url, 'ascendbank-qa://transfer_out_updated');
    expect(updated?.description, 'Updated description');
    expect(updated?.createdAt, createdAt);
    expect(updated!.updatedAt.isAfter(originalUpdatedAt), isTrue);
    expect(updated.isFavorite, isTrue);
    expect(updated.openCount, 3);
    expect(updated.lastOpenedAt, lastOpenedAt);
  });

  test('returns false when updating a missing deeplink', () async {
    final wasUpdated = await repository.updateDeeplink(
      id: 1,
      name: 'Missing',
      url: 'example://missing',
    );

    expect(wasUpdated, isFalse);
  });

  test('deletes an existing deeplink and returns false when missing', () async {
    final id = await repository.createDeeplink(
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );

    final wasDeleted = await repository.deleteDeeplink(id);
    final missingDelete = await repository.deleteDeeplink(id);

    expect(wasDeleted, isTrue);
    expect(await repository.getDeeplinkById(id), isNull);
    expect(missingDelete, isFalse);
  });

  test('duplicates a deeplink with reset usage state', () async {
    final originalId = await insertDeeplink(
      database,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
      description: 'Original description',
      isFavorite: true,
      openCount: 4,
      lastOpenedAt: DateTime(2026, 8, 11, 12),
    );

    final copiedId = await repository.duplicateDeeplink(originalId);
    final copied = await repository.getDeeplinkById(copiedId!);

    expect(copiedId, isNot(originalId));
    expect(copied?.name, 'Transfer Out (Copy)');
    expect(copied?.url, 'ascendbank-qa://transfer_out');
    expect(copied?.description, 'Original description');
    expect(copied?.isFavorite, isFalse);
    expect(copied?.openCount, 0);
    expect(copied?.lastOpenedAt, isNull);
  });

  test('returns null when duplicating a missing deeplink', () async {
    final copiedId = await repository.duplicateDeeplink(1);

    expect(copiedId, isNull);
  });

  test('toggles favorite and returns false when missing', () async {
    final id = await repository.createDeeplink(
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );

    final firstToggle = await repository.toggleFavorite(id);
    final favorite = await repository.getDeeplinkById(id);
    final secondToggle = await repository.toggleFavorite(id);
    final notFavorite = await repository.getDeeplinkById(id);
    final missingToggle = await repository.toggleFavorite(id + 1);

    expect(firstToggle, isTrue);
    expect(favorite?.isFavorite, isTrue);
    expect(secondToggle, isTrue);
    expect(notFavorite?.isFavorite, isFalse);
    expect(missingToggle, isFalse);
  });

  test(
    'records deeplink opened usage and returns false when missing',
    () async {
      final id = await repository.createDeeplink(
        name: 'Transfer Out',
        url: 'ascendbank-qa://transfer_out',
      );

      final firstRecord = await repository.recordDeeplinkOpened(id);
      final openedOnce = await repository.getDeeplinkById(id);
      final secondRecord = await repository.recordDeeplinkOpened(id);
      final openedTwice = await repository.getDeeplinkById(id);
      final missingRecord = await repository.recordDeeplinkOpened(id + 1);

      expect(firstRecord, isTrue);
      expect(openedOnce?.openCount, 1);
      expect(openedOnce?.lastOpenedAt, isNotNull);
      expect(secondRecord, isTrue);
      expect(openedTwice?.openCount, 2);
      expect(openedTwice?.lastOpenedAt, isNotNull);
      expect(missingRecord, isFalse);
    },
  );
}

Future<int> insertDeeplink(
  AppDatabase database, {
  required String name,
  required String url,
  String? description,
  bool isFavorite = false,
  int openCount = 0,
  DateTime? lastOpenedAt,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime(2026, 8, 11, 10);

  return database
      .into(database.deeplinks)
      .insert(
        DeeplinksCompanion.insert(
          name: name,
          url: url,
          description: Value(description),
          isFavorite: Value(isFavorite),
          openCount: Value(openCount),
          lastOpenedAt: Value(lastOpenedAt),
          createdAt: createdAt ?? now,
          updatedAt: updatedAt ?? now,
        ),
      );
}

Future<void> _waitForEmissionCount(
  List<List<Deeplink>> emittedLists,
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
