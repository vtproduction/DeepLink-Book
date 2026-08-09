import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

QueryExecutor openDatabaseConnection() {
  return LazyDatabase(() async {
    final appDirectory = await getApplicationSupportDirectory();
    final databaseFile = File(
      path.join(appDirectory.path, 'deeplink_manager.sqlite'),
    );

    return NativeDatabase.createInBackground(databaseFile);
  });
}
