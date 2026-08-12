// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DeeplinksTable extends Deeplinks
    with TableInfo<$DeeplinksTable, Deeplink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeeplinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _openCountMeta = const VerificationMeta(
    'openCount',
  );
  @override
  late final GeneratedColumn<int> openCount = GeneratedColumn<int>(
    'open_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastOpenedAtMeta = const VerificationMeta(
    'lastOpenedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastOpenedAt = GeneratedColumn<DateTime>(
    'last_opened_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    url,
    description,
    isFavorite,
    openCount,
    lastOpenedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deeplinks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Deeplink> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('open_count')) {
      context.handle(
        _openCountMeta,
        openCount.isAcceptableOrUnknown(data['open_count']!, _openCountMeta),
      );
    }
    if (data.containsKey('last_opened_at')) {
      context.handle(
        _lastOpenedAtMeta,
        lastOpenedAt.isAcceptableOrUnknown(
          data['last_opened_at']!,
          _lastOpenedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Deeplink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Deeplink(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      openCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}open_count'],
      )!,
      lastOpenedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_opened_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DeeplinksTable createAlias(String alias) {
    return $DeeplinksTable(attachedDatabase, alias);
  }
}

class Deeplink extends DataClass implements Insertable<Deeplink> {
  final int id;
  final String name;
  final String url;
  final String? description;
  final bool isFavorite;
  final int openCount;
  final DateTime? lastOpenedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Deeplink({
    required this.id,
    required this.name,
    required this.url,
    this.description,
    required this.isFavorite,
    required this.openCount,
    this.lastOpenedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['url'] = Variable<String>(url);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['open_count'] = Variable<int>(openCount);
    if (!nullToAbsent || lastOpenedAt != null) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DeeplinksCompanion toCompanion(bool nullToAbsent) {
    return DeeplinksCompanion(
      id: Value(id),
      name: Value(name),
      url: Value(url),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      isFavorite: Value(isFavorite),
      openCount: Value(openCount),
      lastOpenedAt: lastOpenedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOpenedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Deeplink.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Deeplink(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      url: serializer.fromJson<String>(json['url']),
      description: serializer.fromJson<String?>(json['description']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      openCount: serializer.fromJson<int>(json['openCount']),
      lastOpenedAt: serializer.fromJson<DateTime?>(json['lastOpenedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'url': serializer.toJson<String>(url),
      'description': serializer.toJson<String?>(description),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'openCount': serializer.toJson<int>(openCount),
      'lastOpenedAt': serializer.toJson<DateTime?>(lastOpenedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Deeplink copyWith({
    int? id,
    String? name,
    String? url,
    Value<String?> description = const Value.absent(),
    bool? isFavorite,
    int? openCount,
    Value<DateTime?> lastOpenedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Deeplink(
    id: id ?? this.id,
    name: name ?? this.name,
    url: url ?? this.url,
    description: description.present ? description.value : this.description,
    isFavorite: isFavorite ?? this.isFavorite,
    openCount: openCount ?? this.openCount,
    lastOpenedAt: lastOpenedAt.present ? lastOpenedAt.value : this.lastOpenedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Deeplink copyWithCompanion(DeeplinksCompanion data) {
    return Deeplink(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      url: data.url.present ? data.url.value : this.url,
      description: data.description.present
          ? data.description.value
          : this.description,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      openCount: data.openCount.present ? data.openCount.value : this.openCount,
      lastOpenedAt: data.lastOpenedAt.present
          ? data.lastOpenedAt.value
          : this.lastOpenedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Deeplink(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('description: $description, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('openCount: $openCount, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    url,
    description,
    isFavorite,
    openCount,
    lastOpenedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Deeplink &&
          other.id == this.id &&
          other.name == this.name &&
          other.url == this.url &&
          other.description == this.description &&
          other.isFavorite == this.isFavorite &&
          other.openCount == this.openCount &&
          other.lastOpenedAt == this.lastOpenedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DeeplinksCompanion extends UpdateCompanion<Deeplink> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> url;
  final Value<String?> description;
  final Value<bool> isFavorite;
  final Value<int> openCount;
  final Value<DateTime?> lastOpenedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const DeeplinksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.url = const Value.absent(),
    this.description = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.openCount = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DeeplinksCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String url,
    this.description = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.openCount = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : name = Value(name),
       url = Value(url),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Deeplink> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? url,
    Expression<String>? description,
    Expression<bool>? isFavorite,
    Expression<int>? openCount,
    Expression<DateTime>? lastOpenedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (url != null) 'url': url,
      if (description != null) 'description': description,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (openCount != null) 'open_count': openCount,
      if (lastOpenedAt != null) 'last_opened_at': lastOpenedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DeeplinksCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? url,
    Value<String?>? description,
    Value<bool>? isFavorite,
    Value<int>? openCount,
    Value<DateTime?>? lastOpenedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return DeeplinksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      description: description ?? this.description,
      isFavorite: isFavorite ?? this.isFavorite,
      openCount: openCount ?? this.openCount,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (openCount.present) {
      map['open_count'] = Variable<int>(openCount.value);
    }
    if (lastOpenedAt.present) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeeplinksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('description: $description, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('openCount: $openCount, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DeeplinksTable deeplinks = $DeeplinksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [deeplinks];
}

typedef $$DeeplinksTableCreateCompanionBuilder =
    DeeplinksCompanion Function({
      Value<int> id,
      required String name,
      required String url,
      Value<String?> description,
      Value<bool> isFavorite,
      Value<int> openCount,
      Value<DateTime?> lastOpenedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$DeeplinksTableUpdateCompanionBuilder =
    DeeplinksCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> url,
      Value<String?> description,
      Value<bool> isFavorite,
      Value<int> openCount,
      Value<DateTime?> lastOpenedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$DeeplinksTableFilterComposer
    extends Composer<_$AppDatabase, $DeeplinksTable> {
  $$DeeplinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openCount => $composableBuilder(
    column: $table.openCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeeplinksTableOrderingComposer
    extends Composer<_$AppDatabase, $DeeplinksTable> {
  $$DeeplinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openCount => $composableBuilder(
    column: $table.openCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeeplinksTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeeplinksTable> {
  $$DeeplinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<int> get openCount =>
      $composableBuilder(column: $table.openCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DeeplinksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeeplinksTable,
          Deeplink,
          $$DeeplinksTableFilterComposer,
          $$DeeplinksTableOrderingComposer,
          $$DeeplinksTableAnnotationComposer,
          $$DeeplinksTableCreateCompanionBuilder,
          $$DeeplinksTableUpdateCompanionBuilder,
          (Deeplink, BaseReferences<_$AppDatabase, $DeeplinksTable, Deeplink>),
          Deeplink,
          PrefetchHooks Function()
        > {
  $$DeeplinksTableTableManager(_$AppDatabase db, $DeeplinksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeeplinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeeplinksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeeplinksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<int> openCount = const Value.absent(),
                Value<DateTime?> lastOpenedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DeeplinksCompanion(
                id: id,
                name: name,
                url: url,
                description: description,
                isFavorite: isFavorite,
                openCount: openCount,
                lastOpenedAt: lastOpenedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String url,
                Value<String?> description = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<int> openCount = const Value.absent(),
                Value<DateTime?> lastOpenedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => DeeplinksCompanion.insert(
                id: id,
                name: name,
                url: url,
                description: description,
                isFavorite: isFavorite,
                openCount: openCount,
                lastOpenedAt: lastOpenedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeeplinksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeeplinksTable,
      Deeplink,
      $$DeeplinksTableFilterComposer,
      $$DeeplinksTableOrderingComposer,
      $$DeeplinksTableAnnotationComposer,
      $$DeeplinksTableCreateCompanionBuilder,
      $$DeeplinksTableUpdateCompanionBuilder,
      (Deeplink, BaseReferences<_$AppDatabase, $DeeplinksTable, Deeplink>),
      Deeplink,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DeeplinksTableTableManager get deeplinks =>
      $$DeeplinksTableTableManager(_db, _db.deeplinks);
}
