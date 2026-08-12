import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

class DeeplinkRepository {
  DeeplinkRepository(this._database);

  final AppDatabase _database;

  Future<int> createDeeplink({
    required String name,
    required String url,
    String? description,
  }) {
    final now = DateTime.now();

    return _database
        .into(_database.deeplinks)
        .insert(
          DeeplinksCompanion.insert(
            name: name,
            url: url,
            description: Value(description),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<Deeplink?> getDeeplinkById(int id) {
    return (_database.select(
      _database.deeplinks,
    )..where((deeplink) => deeplink.id.equals(id))).getSingleOrNull();
  }

  Future<List<Deeplink>> getAllDeeplinks() {
    return _orderedDeeplinksQuery().get();
  }

  Stream<List<Deeplink>> watchAllDeeplinks() {
    return _orderedDeeplinksQuery().watch();
  }

  Future<bool> updateDeeplink({
    required int id,
    required String name,
    required String url,
    String? description,
  }) async {
    final updatedRows =
        await (_database.update(
          _database.deeplinks,
        )..where((deeplink) => deeplink.id.equals(id))).write(
          DeeplinksCompanion(
            name: Value(name),
            url: Value(url),
            description: Value(description),
            updatedAt: Value(DateTime.now()),
          ),
        );

    return updatedRows > 0;
  }

  Future<bool> deleteDeeplink(int id) async {
    final deletedRows = await (_database.delete(
      _database.deeplinks,
    )..where((deeplink) => deeplink.id.equals(id))).go();

    return deletedRows > 0;
  }

  Future<int?> duplicateDeeplink(int id) async {
    final original = await getDeeplinkById(id);

    if (original == null) {
      return null;
    }

    return createDeeplink(
      name: '${original.name} (Copy)',
      url: original.url,
      description: original.description,
    );
  }

  Future<bool> toggleFavorite(int id) async {
    final deeplink = await getDeeplinkById(id);

    if (deeplink == null) {
      return false;
    }

    final updatedRows =
        await (_database.update(
          _database.deeplinks,
        )..where((table) => table.id.equals(id))).write(
          DeeplinksCompanion(
            isFavorite: Value(!deeplink.isFavorite),
            updatedAt: Value(DateTime.now()),
          ),
        );

    return updatedRows > 0;
  }

  Future<bool> recordDeeplinkOpened(int id) async {
    final deeplink = await getDeeplinkById(id);

    if (deeplink == null) {
      return false;
    }

    final now = DateTime.now();
    final updatedRows =
        await (_database.update(
          _database.deeplinks,
        )..where((table) => table.id.equals(id))).write(
          DeeplinksCompanion(
            openCount: Value(deeplink.openCount + 1),
            lastOpenedAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    return updatedRows > 0;
  }

  SimpleSelectStatement<$DeeplinksTable, Deeplink> _orderedDeeplinksQuery() {
    return _database.select(_database.deeplinks)..orderBy([
      (deeplink) =>
          OrderingTerm(expression: deeplink.updatedAt, mode: OrderingMode.desc),
    ]);
  }
}

final deeplinkRepositoryProvider = Provider<DeeplinkRepository>((ref) {
  return DeeplinkRepository(ref.watch(appDatabaseProvider));
});
