import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

class HistoryRepository {
  HistoryRepository(this._database);

  final AppDatabase _database;

  Future<int> createHistory({
    int? deeplinkId,
    required String name,
    required String url,
    required bool isSuccess,
    String? errorMessage,
  }) {
    return _database
        .into(_database.deeplinkHistories)
        .insert(
          DeeplinkHistoriesCompanion.insert(
            deeplinkId: Value(deeplinkId),
            name: name,
            url: url,
            isSuccess: isSuccess,
            errorMessage: Value(errorMessage),
            openedAt: DateTime.now(),
          ),
        );
  }

  Future<List<DeeplinkHistory>> getAllHistory() {
    return _orderedHistoryQuery().get();
  }

  Stream<List<DeeplinkHistory>> watchAllHistory() {
    return _orderedHistoryQuery().watch();
  }

  Stream<List<DeeplinkHistory>> watchRecentHistory({required int limit}) {
    return (_orderedHistoryQuery()..limit(limit)).watch();
  }

  Future<bool> deleteHistory(int id) async {
    final deletedRows = await (_database.delete(
      _database.deeplinkHistories,
    )..where((history) => history.id.equals(id))).go();

    return deletedRows > 0;
  }

  Future<int> clearHistory() {
    return _database.delete(_database.deeplinkHistories).go();
  }

  SimpleSelectStatement<$DeeplinkHistoriesTable, DeeplinkHistory>
  _orderedHistoryQuery() {
    return _database.select(_database.deeplinkHistories)..orderBy([
      (history) =>
          OrderingTerm(expression: history.openedAt, mode: OrderingMode.desc),
      (history) =>
          OrderingTerm(expression: history.id, mode: OrderingMode.desc),
    ]);
  }
}

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(ref.watch(appDatabaseProvider));
});
