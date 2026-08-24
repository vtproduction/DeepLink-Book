import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../data/environment_repository.dart';
import '../../projects/providers/project_providers.dart';

class CurrentEnvironmentId extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? environmentId) {
    state = environmentId;
  }
}

final currentEnvironmentIdProvider =
    NotifierProvider<CurrentEnvironmentId, int?>(CurrentEnvironmentId.new);

final environmentsForProjectProvider =
    StreamProvider.family<List<Environment>, int>((ref, projectId) {
      final repository = ref.watch(environmentRepositoryProvider);

      return repository.watchEnvironmentsForProject(projectId);
    });

final environmentsForCurrentProjectProvider = StreamProvider<List<Environment>>(
  (ref) {
    final projectId = ref.watch(currentProjectIdProvider);

    if (projectId == null) {
      return Stream.value(const []);
    }

    final repository = ref.watch(environmentRepositoryProvider);

    return repository.watchEnvironmentsForProject(projectId);
  },
);

final currentEnvironmentProvider = Provider<AsyncValue<Environment?>>((ref) {
  final environments = ref.watch(environmentsForCurrentProjectProvider);
  final currentEnvironmentId = ref.watch(currentEnvironmentIdProvider);

  return environments.whenData((environments) {
    if (currentEnvironmentId == null) {
      return null;
    }

    for (final environment in environments) {
      if (environment.id == currentEnvironmentId) {
        return environment;
      }
    }

    return null;
  });
});
