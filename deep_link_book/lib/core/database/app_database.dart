import 'package:drift/drift.dart';

import 'tables/deeplink_histories_table.dart';
import 'tables/deeplink_variants_table.dart';
import 'tables/deeplinks_table.dart';
import 'tables/environments_table.dart';
import 'tables/projects_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Projects,
    Environments,
    Deeplinks,
    DeeplinkHistories,
    DeeplinkVariants,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  static const defaultProjectName = 'My Deeplinks';
  static const defaultEnvironmentName = 'Default';

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        await _createDefaultProjectAndEnvironment();
      },
      onUpgrade: (m, from, to) async {
        if (from < 4) {
          await m.createTable(projects);
          await m.createTable(environments);
        }
        if (from < 2) {
          await m.createTable(deeplinks);
        }
        if (from < 3) {
          await m.createTable(deeplinkHistories);
        }
        if (from < 5) {
          await m.createTable(deeplinkVariants);
        }
        if (from < 4) {
          if (from >= 2) {
            await m.addColumn(deeplinks, deeplinks.projectId);
            await m.addColumn(deeplinks, deeplinks.environmentId);
          }
          await _createDefaultProjectAndEnvironment();
          await customStatement(
            '''
            UPDATE deeplinks
            SET project_id = (
              SELECT id
              FROM projects
              WHERE name = ?
              ORDER BY id
              LIMIT 1
            )
            WHERE project_id IS NULL
            ''',
            [defaultProjectName],
          );
        }
      },
    );
  }

  Future<void> _createDefaultProjectAndEnvironment() async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await customStatement(
      '''
      INSERT INTO projects (name, description, created_at, updated_at)
      SELECT ?, NULL, ?, ?
      WHERE NOT EXISTS (
        SELECT 1 FROM projects WHERE name = ?
      )
      ''',
      [defaultProjectName, now, now, defaultProjectName],
    );

    await customStatement(
      '''
      INSERT INTO environments (project_id, name, scheme, created_at, updated_at)
      SELECT id, ?, NULL, ?, ?
      FROM projects
      WHERE name = ?
      ORDER BY id
      LIMIT 1
      ''',
      [defaultEnvironmentName, now, now, defaultProjectName],
    );
  }
}
