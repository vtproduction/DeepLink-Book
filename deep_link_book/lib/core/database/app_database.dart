import 'package:drift/drift.dart';

import 'tables/deeplinks_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Deeplinks])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.createTable(deeplinks);
        }
      },
    );
  }
}
