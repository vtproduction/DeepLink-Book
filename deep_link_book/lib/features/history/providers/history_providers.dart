import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../data/history_repository.dart';

final historyProvider = StreamProvider<List<DeeplinkHistory>>((ref) {
  final repository = ref.watch(historyRepositoryProvider);

  return repository.watchAllHistory();
});
