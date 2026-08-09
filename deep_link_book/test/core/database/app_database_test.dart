import 'package:deep_link_book/core/database/app_database.dart';
import 'package:deep_link_book/core/database/database_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('can create an in-memory database', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    expect(database.schemaVersion, 1);
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
}
