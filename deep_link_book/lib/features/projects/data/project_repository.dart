import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

class ProjectRepository {
  ProjectRepository(this._database);

  final AppDatabase _database;

  Future<int> createProject({required String name, String? description}) {
    final now = DateTime.now();

    return _database
        .into(_database.projects)
        .insert(
          ProjectsCompanion.insert(
            name: name,
            description: Value(description),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<Project> getOrCreateDefaultProject() async {
    final existing =
        await (_database.select(_database.projects)
              ..where(
                (project) =>
                    project.name.equals(AppDatabase.defaultProjectName),
              )
              ..orderBy([(project) => OrderingTerm.asc(project.id)])
              ..limit(1))
            .getSingleOrNull();

    if (existing != null) {
      return existing;
    }

    final id = await createProject(name: AppDatabase.defaultProjectName);
    final created = await getProjectById(id);

    if (created == null) {
      throw StateError('Unable to create the default project.');
    }

    return created;
  }

  Future<List<Project>> getAllProjects() {
    return _orderedProjectsQuery().get();
  }

  Stream<List<Project>> watchAllProjects() {
    return _orderedProjectsQuery().watch();
  }

  Future<Project?> getProjectById(int id) {
    return (_database.select(
      _database.projects,
    )..where((project) => project.id.equals(id))).getSingleOrNull();
  }

  Future<bool> updateProject({
    required int id,
    required String name,
    String? description,
  }) async {
    final updatedRows =
        await (_database.update(
          _database.projects,
        )..where((project) => project.id.equals(id))).write(
          ProjectsCompanion(
            name: Value(name),
            description: Value(description),
            updatedAt: Value(DateTime.now()),
          ),
        );

    return updatedRows > 0;
  }

  Future<bool> deleteProject(int id) async {
    final deeplinks = await (_database.select(
      _database.deeplinks,
    )..where((deeplink) => deeplink.projectId.equals(id))).get();
    final environments = await (_database.select(
      _database.environments,
    )..where((environment) => environment.projectId.equals(id))).get();

    if (deeplinks.isNotEmpty || environments.isNotEmpty) {
      return false;
    }

    final deletedRows = await (_database.delete(
      _database.projects,
    )..where((project) => project.id.equals(id))).go();

    return deletedRows > 0;
  }

  SimpleSelectStatement<$ProjectsTable, Project> _orderedProjectsQuery() {
    return _database.select(_database.projects)..orderBy([
      (project) =>
          OrderingTerm(expression: project.updatedAt, mode: OrderingMode.desc),
    ]);
  }
}

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(ref.watch(appDatabaseProvider));
});
