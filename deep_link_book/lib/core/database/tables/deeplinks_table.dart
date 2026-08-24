import 'package:drift/drift.dart';

import 'environments_table.dart';
import 'projects_table.dart';

class Deeplinks extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get projectId => integer().nullable().references(
    Projects,
    #id,
    onDelete: KeyAction.restrict,
  )();

  IntColumn get environmentId => integer().nullable().references(
    Environments,
    #id,
    onDelete: KeyAction.setNull,
  )();

  TextColumn get name => text()();

  TextColumn get url => text()();

  TextColumn get description => text().nullable()();

  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  IntColumn get openCount => integer().withDefault(const Constant(0))();

  DateTimeColumn get lastOpenedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();
}
