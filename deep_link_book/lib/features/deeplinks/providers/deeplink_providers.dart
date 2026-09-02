import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../environments/providers/environment_providers.dart';
import '../../projects/providers/project_providers.dart';
import '../data/deeplink_repository.dart';

final deeplinksProvider = StreamProvider<List<Deeplink>>((ref) {
  final repository = ref.watch(deeplinkRepositoryProvider);
  final projectId = ref.watch(currentProjectIdProvider);
  final environmentId = ref.watch(currentEnvironmentIdProvider);

  if (projectId == null) {
    return Stream.value(const []);
  }

  return repository.watchDeeplinks(
    projectId: projectId,
    environmentId: environmentId,
  );
});

final allDeeplinksProvider = StreamProvider<List<Deeplink>>((ref) {
  final repository = ref.watch(deeplinkRepositoryProvider);

  return repository.watchAllDeeplinks();
});

final deeplinkByIdProvider = FutureProvider.family<Deeplink?, int>((ref, id) {
  final repository = ref.watch(deeplinkRepositoryProvider);

  return repository.getDeeplinkById(id);
});
