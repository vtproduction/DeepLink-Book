import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

class EnvironmentRepository {
  EnvironmentRepository(this._database);

  final AppDatabase _database;

  Future<int> createEnvironment({
    required int projectId,
    required String name,
    String? scheme,
  }) {
    final now = DateTime.now();

    return _database
        .into(_database.environments)
        .insert(
          EnvironmentsCompanion.insert(
            projectId: projectId,
            name: name,
            scheme: Value(scheme),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<List<Environment>> getEnvironmentsForProject(int projectId) {
    return _environmentsForProjectQuery(projectId).get();
  }

  Stream<List<Environment>> watchEnvironmentsForProject(int projectId) {
    return _environmentsForProjectQuery(projectId).watch();
  }

  Future<Environment?> getEnvironmentById(int id) {
    return (_database.select(
      _database.environments,
    )..where((environment) => environment.id.equals(id))).getSingleOrNull();
  }

  Future<bool> updateEnvironment({
    required int id,
    required String name,
    String? scheme,
  }) async {
    final updatedRows =
        await (_database.update(
          _database.environments,
        )..where((environment) => environment.id.equals(id))).write(
          EnvironmentsCompanion(
            name: Value(name),
            scheme: Value(scheme),
            updatedAt: Value(DateTime.now()),
          ),
        );

    return updatedRows > 0;
  }

  Future<bool> deleteEnvironment(int id) async {
    return _database.transaction(() async {
      await (_database.update(_database.deeplinks)
            ..where((deeplink) => deeplink.environmentId.equals(id)))
          .write(const DeeplinksCompanion(environmentId: Value<int?>(null)));

      final deletedRows = await (_database.delete(
        _database.environments,
      )..where((environment) => environment.id.equals(id))).go();

      return deletedRows > 0;
    });
  }

  SimpleSelectStatement<$EnvironmentsTable, Environment>
  _environmentsForProjectQuery(int projectId) {
    return _database.select(_database.environments)
      ..where((environment) => environment.projectId.equals(projectId))
      ..orderBy([
        (environment) =>
            OrderingTerm(expression: environment.name, mode: OrderingMode.asc),
      ]);
  }
}

final environmentRepositoryProvider = Provider<EnvironmentRepository>((ref) {
  return EnvironmentRepository(ref.watch(appDatabaseProvider));
});
