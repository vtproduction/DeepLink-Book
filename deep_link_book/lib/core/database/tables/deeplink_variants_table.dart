import 'package:drift/drift.dart';

import 'deeplinks_table.dart';

class DeeplinkVariants extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get deeplinkId =>
      integer().references(Deeplinks, #id, onDelete: KeyAction.cascade)();

  TextColumn get name => text()();

  TextColumn get overridesJson => text().withDefault(const Constant('{}'))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();
}
