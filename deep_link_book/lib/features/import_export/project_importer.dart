import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../deeplinks/validation/deeplink_validator.dart';
import 'models/project_export_data.dart';

class ProjectImportResult {
  const ProjectImportResult({
    required this.projectId,
    required this.projectName,
    required this.environmentCount,
    required this.deeplinkCount,
  });

  final int projectId;
  final String projectName;
  final int environmentCount;
  final int deeplinkCount;
}

class ProjectImportPreview {
  const ProjectImportPreview({
    required this.projectName,
    required this.environmentCount,
    required this.deeplinkCount,
  });

  final String projectName;
  final int environmentCount;
  final int deeplinkCount;
}

class ProjectImporter {
  ProjectImporter(this._database);

  final AppDatabase _database;

  ProjectImportPreview previewImport(String content) {
    final data = _parseAndValidate(content);

    return ProjectImportPreview(
      projectName: data.project.name.trim(),
      environmentCount: data.environments.length,
      deeplinkCount: data.deeplinks.length,
    );
  }

  Future<ProjectImportResult> importProject(String content) async {
    final data = _parseAndValidate(content);
    final existingProjectNames = await _existingProjectNames();
    final importedProjectName = _uniqueImportedProjectName(
      data.project.name.trim(),
      existingProjectNames,
    );

    return _database.transaction(() async {
      final now = DateTime.now();
      final projectId = await _database
          .into(_database.projects)
          .insert(
            ProjectsCompanion.insert(
              name: importedProjectName,
              description: Value(_trimOptional(data.project.description)),
              createdAt: now,
              updatedAt: now,
            ),
          );
      final environmentIdsByKey = <String, int>{};

      for (final environment in data.environments) {
        final environmentId = await _database
            .into(_database.environments)
            .insert(
              EnvironmentsCompanion.insert(
                projectId: projectId,
                name: environment.name.trim(),
                scheme: Value(_trimOptional(environment.scheme)),
                createdAt: now,
                updatedAt: now,
              ),
            );

        environmentIdsByKey[environment.key] = environmentId;
      }

      for (final deeplink in data.deeplinks) {
        final environmentKey = deeplink.environmentKey;

        await _database
            .into(_database.deeplinks)
            .insert(
              DeeplinksCompanion.insert(
                projectId: Value(projectId),
                environmentId: Value(
                  environmentKey == null
                      ? null
                      : environmentIdsByKey[environmentKey],
                ),
                name: deeplink.name.trim(),
                url: deeplink.url.trim(),
                description: Value(_trimOptional(deeplink.description)),
                isFavorite: Value(deeplink.favorite),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }

      return ProjectImportResult(
        projectId: projectId,
        projectName: importedProjectName,
        environmentCount: data.environments.length,
        deeplinkCount: data.deeplinks.length,
      );
    });
  }

  ProjectExportData _parseAndValidate(String content) {
    final ProjectExportData data;

    try {
      data = ProjectExportData.fromJsonString(content);
    } on FormatException catch (error) {
      throw ProjectImportException(error.message);
    } catch (_) {
      throw const ProjectImportException('Import file is not valid JSON.');
    }

    _validate(data);

    return data;
  }

  void _validate(ProjectExportData data) {
    if (data.version != ProjectExportData.currentVersion) {
      throw ProjectImportException(
        'Unsupported export version: ${data.version}.',
      );
    }

    if (data.project.name.trim().isEmpty) {
      throw const ProjectImportException('Project name is required.');
    }

    final environmentKeys = <String>{};

    for (final environment in data.environments) {
      final key = environment.key.trim();

      if (key.isEmpty) {
        throw const ProjectImportException('Environment key is required.');
      }

      if (key != environment.key) {
        throw ProjectImportException('Environment key "$key" has extra space.');
      }

      if (!environmentKeys.add(key)) {
        throw ProjectImportException('Duplicate environment key: $key.');
      }

      if (environment.name.trim().isEmpty) {
        throw ProjectImportException('Environment "$key" needs a name.');
      }
    }

    for (final deeplink in data.deeplinks) {
      final nameError = DeeplinkValidator.validateName(deeplink.name);

      if (nameError != null) {
        throw ProjectImportException('Invalid deeplink name: $nameError');
      }

      final urlError = DeeplinkValidator.validateUrl(deeplink.url);

      if (urlError != null) {
        throw ProjectImportException(
          'Invalid deeplink "${deeplink.name}": $urlError',
        );
      }

      final environmentKey = deeplink.environmentKey;

      if (environmentKey != null && environmentKey.trim() != environmentKey) {
        throw ProjectImportException(
          'Deeplink "${deeplink.name}" has an invalid environment key.',
        );
      }

      if (environmentKey != null && !environmentKeys.contains(environmentKey)) {
        throw ProjectImportException(
          'Deeplink "${deeplink.name}" references an unknown environment.',
        );
      }
    }
  }

  Future<Set<String>> _existingProjectNames() async {
    final projects = await _database.select(_database.projects).get();

    return projects.map((project) => project.name).toSet();
  }

  String _uniqueImportedProjectName(
    String baseName,
    Set<String> existingNames,
  ) {
    if (!existingNames.contains(baseName)) {
      return baseName;
    }

    final importedName = '$baseName (Imported)';

    if (!existingNames.contains(importedName)) {
      return importedName;
    }

    var suffix = 2;

    while (existingNames.contains('$baseName (Imported $suffix)')) {
      suffix += 1;
    }

    return '$baseName (Imported $suffix)';
  }

  String? _trimOptional(String? value) {
    final trimmed = value?.trim();

    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }
}

class ProjectImportException implements Exception {
  const ProjectImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

final projectImporterProvider = Provider<ProjectImporter>((ref) {
  return ProjectImporter(ref.watch(appDatabaseProvider));
});
