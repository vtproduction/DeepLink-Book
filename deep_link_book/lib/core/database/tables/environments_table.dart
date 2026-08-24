import 'package:drift/drift.dart';

import 'projects_table.dart';

class Environments extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get projectId =>
      integer().references(Projects, #id, onDelete: KeyAction.restrict)();

  TextColumn get name => text()();

  TextColumn get scheme => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();
}
