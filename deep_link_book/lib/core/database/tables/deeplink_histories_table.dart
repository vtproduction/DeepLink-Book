import 'package:drift/drift.dart';

class DeeplinkHistories extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get deeplinkId => integer().nullable()();

  TextColumn get name => text()();

  TextColumn get url => text()();

  BoolColumn get isSuccess => boolean()();

  TextColumn get errorMessage => text().nullable()();

  DateTimeColumn get openedAt => dateTime()();
}
