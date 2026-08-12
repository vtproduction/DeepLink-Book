import 'dart:io';

import 'package:deep_link_book/core/database/app_database.dart';
import 'package:deep_link_book/core/database/database_provider.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test('can create an in-memory database', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    expect(database.schemaVersion, 2);
  });

  test('can execute a simple SQL query', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final result = await database.customSelect('SELECT 1 AS value').getSingle();

    expect(result.read<int>('value'), 1);
  });

  test('can close without throwing', () async {
    final database = AppDatabase(NativeDatabase.memory());

    await expectLater(database.close(), completes);
  });

  test('provider creates an AppDatabase', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final database = container.read(appDatabaseProvider);

    expect(database, isA<AppDatabase>());
  });

  test('provider runs dispose cleanup for an overridden database', () {
    final database = AppDatabase(NativeDatabase.memory());
    var didDispose = false;
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(() {
            didDispose = true;
            database.close();
          });
          return database;
        }),
      ],
    );

    expect(container.read(appDatabaseProvider), same(database));

    container.dispose();

    expect(didDispose, isTrue);
  });

  test('fresh database creates the deeplinks table', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final table = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'deeplinks'",
        )
        .getSingleOrNull();

    expect(table?.read<String>('name'), 'deeplinks');
  });

  test('inserts a minimal deeplink with default values', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime(2026, 8, 11, 10);

    await database
        .into(database.deeplinks)
        .insert(
          DeeplinksCompanion.insert(
            name: 'OpenAI',
            url: 'https://openai.com',
            createdAt: now,
            updatedAt: now,
          ),
        );

    final deeplink = await database.select(database.deeplinks).getSingle();

    expect(deeplink.name, 'OpenAI');
    expect(deeplink.url, 'https://openai.com');
    expect(deeplink.isFavorite, isFalse);
    expect(deeplink.openCount, 0);
    expect(deeplink.description, isNull);
    expect(deeplink.lastOpenedAt, isNull);
    expect(deeplink.createdAt, now);
    expect(deeplink.updatedAt, now);
  });

  test('persists optional deeplink fields', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final createdAt = DateTime(2026, 8, 11, 10);
    final lastOpenedAt = DateTime(2026, 8, 11, 11);

    await database
        .into(database.deeplinks)
        .insert(
          DeeplinksCompanion.insert(
            name: 'Maps',
            url: 'maps://place',
            description: const Value('Open a saved map location'),
            lastOpenedAt: Value(lastOpenedAt),
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );

    final deeplink = await database.select(database.deeplinks).getSingle();

    expect(deeplink.description, 'Open a saved map location');
    expect(deeplink.lastOpenedAt, lastOpenedAt);
  });

  test('generates different primary keys', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime(2026, 8, 11, 10);

    final firstId = await database
        .into(database.deeplinks)
        .insert(
          DeeplinksCompanion.insert(
            name: 'First',
            url: 'example://first',
            createdAt: now,
            updatedAt: now,
          ),
        );
    final secondId = await database
        .into(database.deeplinks)
        .insert(
          DeeplinksCompanion.insert(
            name: 'Second',
            url: 'example://second',
            createdAt: now,
            updatedAt: now,
          ),
        );

    expect(firstId, isNot(secondId));
  });

  test('migrates a version 1 database to version 2', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'deeplink_manager_migration_test_',
    );
    addTearDown(() => tempDirectory.delete(recursive: true));
    final databaseFile = File(path.join(tempDirectory.path, 'test.sqlite'));
    final legacyDatabase = sqlite.sqlite3.open(databaseFile.path);
    legacyDatabase.execute('PRAGMA user_version = 1');
    legacyDatabase.close();

    final database = AppDatabase(NativeDatabase(databaseFile));
    addTearDown(database.close);

    final table = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'deeplinks'",
        )
        .getSingleOrNull();
    final version = await database
        .customSelect('PRAGMA user_version')
        .map((row) => row.read<int>('user_version'))
        .getSingle();

    expect(table?.read<String>('name'), 'deeplinks');
    expect(version, 2);
  });
}
