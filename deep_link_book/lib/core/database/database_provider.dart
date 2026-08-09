import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'database_connection.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase(openDatabaseConnection());

  ref.onDispose(database.close);

  return database;
});
