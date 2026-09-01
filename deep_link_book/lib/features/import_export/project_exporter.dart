import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import 'models/project_export_data.dart';

class ProjectExporter {
  ProjectExporter(this._database);

  final AppDatabase _database;

  Future<ProjectExportData?> exportProject(int projectId) async {
    final project = await (_database.select(
      _database.projects,
    )..where((project) => project.id.equals(projectId))).getSingleOrNull();

    if (project == null) {
      return null;
    }

    final environments =
        await (_database.select(_database.environments)
              ..where((environment) => environment.projectId.equals(projectId))
              ..orderBy([(environment) => OrderingTerm.asc(environment.name)]))
            .get();
    final deeplinks =
        await (_database.select(_database.deeplinks)
              ..where((deeplink) => deeplink.projectId.equals(projectId))
              ..orderBy([(deeplink) => OrderingTerm.asc(deeplink.name)]))
            .get();
    final environmentKeys = <int, String>{};

    for (var index = 0; index < environments.length; index += 1) {
      environmentKeys[environments[index].id] = 'environment_${index + 1}';
    }

    return ProjectExportData(
      version: ProjectExportData.currentVersion,
      project: ExportedProject(
        name: project.name,
        description: project.description,
      ),
      environments: environments.map((environment) {
        return ExportedEnvironment(
          key: environmentKeys[environment.id]!,
          name: environment.name,
          scheme: environment.scheme,
        );
      }).toList(),
      deeplinks: deeplinks.map((deeplink) {
        return ExportedDeeplink(
          name: deeplink.name,
          description: deeplink.description,
          url: deeplink.url,
          environmentKey: deeplink.environmentId == null
              ? null
              : environmentKeys[deeplink.environmentId],
          favorite: deeplink.isFavorite,
        );
      }).toList(),
    );
  }
}

final projectExporterProvider = Provider<ProjectExporter>((ref) {
  return ProjectExporter(ref.watch(appDatabaseProvider));
});
