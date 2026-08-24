import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../data/project_repository.dart';

final projectsProvider = StreamProvider<List<Project>>((ref) {
  final repository = ref.watch(projectRepositoryProvider);

  return repository.watchAllProjects();
});

class CurrentProjectId extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? projectId) {
    state = projectId;
  }
}

final currentProjectIdProvider = NotifierProvider<CurrentProjectId, int?>(
  CurrentProjectId.new,
);

final currentProjectProvider = Provider<AsyncValue<Project?>>((ref) {
  final projects = ref.watch(projectsProvider);
  final currentProjectId = ref.watch(currentProjectIdProvider);

  return projects.whenData((projects) {
    if (projects.isEmpty) {
      return null;
    }

    if (currentProjectId == null) {
      return null;
    }

    for (final project in projects) {
      if (project.id == currentProjectId) {
        return project;
      }
    }

    return null;
  });
});

final projectByIdProvider = FutureProvider.family<Project?, int>((ref, id) {
  final repository = ref.watch(projectRepositoryProvider);

  return repository.getProjectById(id);
});
