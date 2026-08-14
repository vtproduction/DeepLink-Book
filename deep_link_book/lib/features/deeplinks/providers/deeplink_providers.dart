import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../data/deeplink_repository.dart';

final deeplinksProvider = StreamProvider<List<Deeplink>>((ref) {
  final repository = ref.watch(deeplinkRepositoryProvider);

  return repository.watchAllDeeplinks();
});

final deeplinkByIdProvider = FutureProvider.family<Deeplink?, int>((ref, id) {
  final repository = ref.watch(deeplinkRepositoryProvider);

  return repository.getDeeplinkById(id);
});
