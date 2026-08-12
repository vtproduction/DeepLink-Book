import 'package:drift/drift.dart';

class Deeplinks extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  TextColumn get url => text()();

  TextColumn get description => text().nullable()();

  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  IntColumn get openCount => integer().withDefault(const Constant(0))();

  DateTimeColumn get lastOpenedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();
}
