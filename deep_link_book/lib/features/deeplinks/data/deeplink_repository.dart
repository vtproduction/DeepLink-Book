import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../projects/data/project_repository.dart';

class DeeplinkRepository {
  DeeplinkRepository(this._database, {ProjectRepository? projectRepository})
    : _projectRepository = projectRepository ?? ProjectRepository(_database);

  final AppDatabase _database;
  final ProjectRepository _projectRepository;

  Future<int> createDeeplink({
    int? projectId,
    int? environmentId,
    required String name,
    required String url,
    String? description,
  }) async {
    final now = DateTime.now();
    final resolvedProjectId =
        projectId ?? (await _projectRepository.getOrCreateDefaultProject()).id;

    await _verifyEnvironmentBelongsToProject(
      projectId: resolvedProjectId,
      environmentId: environmentId,
    );

    return _database
        .into(_database.deeplinks)
        .insert(
          DeeplinksCompanion.insert(
            projectId: Value(resolvedProjectId),
            environmentId: Value(environmentId),
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

  Stream<List<Deeplink>> watchDeeplinks({
    required int projectId,
    int? environmentId,
  }) {
    final query = _orderedDeeplinksQuery()
      ..where((deeplink) => deeplink.projectId.equals(projectId));

    if (environmentId != null) {
      query.where((deeplink) => deeplink.environmentId.equals(environmentId));
    }

    return query.watch();
  }

  Future<bool> updateDeeplink({
    required int id,
    int? projectId,
    Value<int?> environmentId = const Value.absent(),
    required String name,
    required String url,
    String? description,
  }) async {
    if (projectId != null || environmentId.present) {
      final existing = await getDeeplinkById(id);

      if (existing == null) {
        return false;
      }

      final resolvedProjectId = projectId ?? existing.projectId;

      if (resolvedProjectId == null) {
        throw StateError('A deeplink must belong to a project.');
      }

      await _verifyEnvironmentBelongsToProject(
        projectId: resolvedProjectId,
        environmentId: environmentId.present
            ? environmentId.value
            : existing.environmentId,
      );
    }

    final updatedRows =
        await (_database.update(
          _database.deeplinks,
        )..where((deeplink) => deeplink.id.equals(id))).write(
          DeeplinksCompanion(
            projectId: Value.absentIfNull(projectId),
            environmentId: environmentId,
            name: Value(name),
            url: Value(url),
            description: Value(description),
            updatedAt: Value(DateTime.now()),
          ),
        );

    return updatedRows > 0;
  }

  Future<void> _verifyEnvironmentBelongsToProject({
    required int projectId,
    required int? environmentId,
  }) async {
    if (environmentId == null) {
      return;
    }

    final environment =
        await (_database.select(_database.environments)
              ..where((environment) => environment.id.equals(environmentId))
              ..where((environment) => environment.projectId.equals(projectId)))
            .getSingleOrNull();

    if (environment == null) {
      throw ArgumentError(
        'The selected environment does not belong to the selected project.',
      );
    }
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
      projectId: original.projectId,
      environmentId: original.environmentId,
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
  return DeeplinkRepository(
    ref.watch(appDatabaseProvider),
    projectRepository: ref.watch(projectRepositoryProvider),
  );
});
